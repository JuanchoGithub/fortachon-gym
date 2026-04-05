import Foundation
import FortachonCore

// MARK: - Auth Models

struct AuthUser: Codable, Sendable {
    let id: String
    let email: String
}

struct AuthResponse: Codable, Sendable {
    let success: Bool
    let user: AuthUser?
    let token: String?
    let error: String?
}

// MARK: - Auth Service

@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published var isAuthenticated = false
    @Published var currentUser: AuthUser?
    @Published var token: String?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiBase = "https://fortachon.vercel.app"
    private let tokenKey = "fortachon_auth_token"
    private let userKey = "fortachon_auth_user"
    
    private init() {
        restoreSession()
    }
    
    // MARK: - Public Methods
    
    func login(email: String, password: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        guard let url = URL(string: "\(apiBase)/api/auth/login"),
              let body = try? JSONEncoder().encode(["email": email, "password": password]) else {
            errorMessage = "Invalid login data"
            isLoading = false
            return false
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                errorMessage = "Invalid server response"
                isLoading = false
                return false
            }
            
            guard httpResponse.statusCode == 200 else {
                let decoder = JSONDecoder()
                if let authResponse = try? decoder.decode(AuthResponse.self, from: data) {
                    errorMessage = authResponse.error ?? "Login failed"
                } else {
                    errorMessage = "Server error: \(httpResponse.statusCode)"
                }
                isLoading = false
                return false
            }
            
            let decoder = JSONDecoder()
            let authResponse = try decoder.decode(AuthResponse.self, from: data)
            
            if authResponse.success, let user = authResponse.user, let token = authResponse.token {
                self.currentUser = user
                self.token = token
                self.isAuthenticated = true
                saveSession(user: user, token: token)
                isLoading = false
                return true
            } else {
                errorMessage = authResponse.error ?? "Login failed"
                isLoading = false
                return false
            }
        } catch {
            errorMessage = "Network error: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    func register(email: String, password: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        guard let url = URL(string: "\(apiBase)/api/auth/register"),
              let body = try? JSONEncoder().encode(["email": email, "password": password]) else {
            errorMessage = "Invalid registration data"
            isLoading = false
            return false
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                errorMessage = "Invalid server response"
                isLoading = false
                return false
            }
            
            guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
                let decoder = JSONDecoder()
                if let authResponse = try? decoder.decode(AuthResponse.self, from: data) {
                    errorMessage = authResponse.error ?? "Registration failed"
                } else {
                    errorMessage = "Server error: \(httpResponse.statusCode)"
                }
                isLoading = false
                return false
            }
            
            let decoder = JSONDecoder()
            let authResponse = try decoder.decode(AuthResponse.self, from: data)
            
            if authResponse.success, let user = authResponse.user, let token = authResponse.token {
                self.currentUser = user
                self.token = token
                self.isAuthenticated = true
                saveSession(user: user, token: token)
                isLoading = false
                return true
            } else {
                errorMessage = authResponse.error ?? "Registration failed"
                isLoading = false
                return false
            }
        } catch {
            errorMessage = "Network error: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    func logout() {
        currentUser = nil
        token = nil
        isAuthenticated = false
        clearSession()
    }
    
    func validateSession() async -> Bool {
        guard let token = token else {
            logout()
            return false
        }
        
        guard let url = URL(string: "\(apiBase)/api/auth/me") else {
            logout()
            return false
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                logout()
                return false
            }
            
            let decoder = JSONDecoder()
            let authResponse = try decoder.decode(AuthResponse.self, from: data)
            
            if authResponse.success, let user = authResponse.user {
                self.currentUser = user
                self.isAuthenticated = true
                return true
            } else {
                logout()
                return false
            }
        } catch {
            logout()
            return false
        }
    }
    
    // MARK: - Cloud Sync Helpers
    
    func pushData(_ data: SyncData) async -> SyncResponse {
        guard let token = token else {
            return SyncResponse(success: false, error: "Not authenticated")
        }
        
        // Create a custom request with auth token
        let payload = ["data": data]
        
        guard let url = URL(string: "\(apiBase)/api/sync/push"),
              let body = try? JSONEncoder().encode(payload) else {
            return SyncResponse(success: false, error: "Invalid request data")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = body
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return SyncResponse(success: false, error: "Invalid response")
            }
            
            guard httpResponse.statusCode == 200 else {
                return SyncResponse(success: false, error: "Server error: \(httpResponse.statusCode)")
            }
            
            let decoder = JSONDecoder()
            let rawResponse = try decoder.decode(RawSyncResponse.self, from: data)
            let syncTime = Date().timeIntervalSince1970
            CloudSyncService.setLastSyncTime(syncTime)
            
            return SyncResponse(
                success: true,
                data: rawResponse.data,
                syncedAt: syncTime,
                isEmpty: rawResponse.isEmpty ?? false
            )
        } catch {
            return SyncResponse(success: false, error: "Network error: \(error.localizedDescription)")
        }
    }
    
    func pullData(since: Double = 0) async -> SyncResponse {
        guard let token = token else {
            return SyncResponse(success: false, error: "Not authenticated")
        }
        
        var urlString = "\(apiBase)/api/sync/pull"
        if since > 0 {
            urlString += "?since=\(since)"
        }
        
        guard let url = URL(string: urlString) else {
            return SyncResponse(success: false, error: "Invalid URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return SyncResponse(success: false, error: "Invalid response")
            }
            
            guard httpResponse.statusCode == 200 else {
                return SyncResponse(success: false, error: "Server error: \(httpResponse.statusCode)")
            }
            
            let decoder = JSONDecoder()
            let rawResponse = try decoder.decode(RawSyncResponse.self, from: data)
            
            return SyncResponse(
                success: true,
                data: rawResponse.data,
                lastUpdated: rawResponse.lastUpdated
            )
        } catch {
            return SyncResponse(success: false, error: "Network error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Private Methods
    
    private func restoreSession() {
        guard let token = UserDefaults.standard.string(forKey: tokenKey) else {
            return
        }
        
        self.token = token
        
        if let userData = UserDefaults.standard.data(forKey: userKey),
           let user = try? JSONDecoder().decode(AuthUser.self, from: userData) {
            self.currentUser = user
            self.isAuthenticated = true
        }
    }
    
    private func saveSession(user: AuthUser, token: String) {
        UserDefaults.standard.set(token, forKey: self.tokenKey)
        if let userData = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(userData, forKey: userKey)
        }
    }
    
    private func clearSession() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: userKey)
    }
}