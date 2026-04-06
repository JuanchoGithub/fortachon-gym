import Foundation

// MARK: - Fuzzy Search Utilities

/// Performs fuzzy/partial matching on exercise names.
/// Supports: exact match, prefix match, substring match, and fuzzy character match.
public func fuzzySearchExercises(
    query: String,
    exercises: [ExerciseM],
    useLocalizedNames: Bool = false
) -> [ExerciseM] {
    guard !query.isEmpty else { return exercises.sorted { $0.name < $1.name } }
    
    let lowercaseQuery = query.lowercased()
    let queryWords = lowercaseQuery.split(separator: " ").map { String($0) }
    
    return exercises.filter { exercise in
        let name = exercise.displayName(useSpanish: useLocalizedNames).lowercased()
        
        // Exact match (highest priority)
        if name == lowercaseQuery { return true }
        
        // Prefix match
        if name.hasPrefix(lowercaseQuery) { return true }
        
        // Substring match
        if name.contains(lowercaseQuery) { return true }
        
        // Word-by-word match (matches exercises that contain all query words)
        let allWordsMatch = queryWords.allSatisfy { name.contains($0) }
        if allWordsMatch { return true }
        
        // Fuzzy match (characters appear in order, not necessarily adjacent)
        if fuzzyMatch(text: name, pattern: lowercaseQuery) { return true }
        
        return false
    }.sorted { a, b in
        let nameA = a.displayName(useSpanish: useLocalizedNames).lowercased()
        let nameB = b.displayName(useSpanish: useLocalizedNames).lowercased()
        
        // Score: lower score = better match
        let scoreA = matchScore(name: nameA, query: lowercaseQuery)
        let scoreB = matchScore(name: nameB, query: lowercaseQuery)
        return scoreA < scoreB
    }
}

/// Fuzzy match: checks if pattern characters appear in order within text
private func fuzzyMatch(text: String, pattern: String) -> Bool {
    var patternIndex = text.startIndex
    for char in pattern {
        if let idx = text[patternIndex...].firstIndex(of: char) {
            patternIndex = text.index(after: idx)
        } else {
            return false
        }
    }
    return true
}

/// Calculate match score (lower is better)
private func matchScore(name: String, query: String) -> Int {
    // Exact match
    if name == query { return 0 }
    
    // Prefix match - score by remaining length
    if name.hasPrefix(query) { return 1 }
    
    // Substring match - score by position
    if let range = name.range(of: query) {
        return name.distance(from: name.startIndex, to: range.lowerBound) + 10
    }
    
    // Word match
    let queryWords = query.split(separator: " ")
    let allFound = queryWords.allSatisfy { name.contains($0) }
    if allFound { return 50 }
    
    // Fuzzy match - score by total distance between matched chars
    return 100
}