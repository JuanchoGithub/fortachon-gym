import Foundation

// MARK: - Exercise Name Localization

/// Spanish translations for exercise names
/// Keys are exercise IDs (e.g., "ex-1", "ex-2")
public let exerciseNamesES: [String: String] = [
    // Chest
    "ex-1": "Press de Banca",
    "ex-11": "Aperturas con Mancuernas",
    "ex-12": "Press Inclinado con Mancuernas",
    "ex-21": "Cruce de Poleas",
    "ex-22": "Press de Banca Declinado",
    "ex-23": "Flexión de Brazos",
    "ex-24": "Fondos",
    "ex-25": "Press de Banca Inclinado",
    "ex-26": "Aperturas en Pec Deck",
    "ex-27": "Press Svend",
    "ex-28": "Press Landmine",
    "ex-29": "Flexión con Déficit",
    "ex-30": "Flexión de Arquero",
    "ex-31": "Press de Pecho en Máquina",
    "ex-32": "Apertura con Cable de Abajo a Arriba",
    "ex-33": "Apertura con Cable de Arriba a Abajo",
    "ex-34": "Press con Disco",
    "ex-35": "Flexión en Suspensión",
    "ex-36": "Apretón Isométrico de Pecho",
    "ex-37": "Press de Banca de Velocidad",
    
    // Back
    "ex-5": "Remo con Barra",
    "ex-10": "Jalón al Pecho",
    "ex-3": "Peso Muerto",
    "ex-6": "Dominada",
    "ex-38": "Remo Sentado",
    "ex-39": "Remo en Barra T",
    "ex-40": "Remo con Mancuerna a un Brazo",
    "ex-41": "Tirón a la Cara (Face Pull)",
    "ex-42": "Remo Invertido",
    "ex-43": "Peso Muerto Parcial (Rack Pull)",
    "ex-44": "Pulldown con Brazos Rectos",
    "ex-45": "Hiperextensión",
    "ex-46": "Superman",
    "ex-47": "Remo Renegado",
    "ex-48": "Remo Meadows",
    "ex-49": "Pull-Over con Cable",
    "ex-50": "Dominada Supina (Chin-Up)",
    "ex-51": "Encogimientos de Hombros",
    "ex-52": "Jalón al Pecho con Agarre Inverso",
    "ex-53": "Band Pull-Apart",
    "ex-54": "Paseo del Granjero",
    "ex-55": "Buenos Días",
    "ex-148": "Tirón Alto con Kettlebell",
    
    // Shoulders
    "ex-4": "Press Militar",
    "ex-56": "Elevación Lateral",
    "ex-57": "Elevación Frontal",
    "ex-58": "Pájaros (Rear Delt Fly)",
    "ex-59": "Remo al Mentón",
    "ex-60": "Press Arnold",
    "ex-61": "Elevación Lateral con Cable",
    "ex-62": "Flexión en Pica",
    "ex-63": "Flexión de Pino",
    "ex-64": "Elevación Lateral Egipcia",
    "ex-65": "Elevación en Y",
    "ex-66": "Press Cubano",
    "ex-67": "Press de Hombros en Máquina",
    "ex-68": "Press Tras Nuca",
    "ex-69": "Elevación Frontal con Disco",
    "ex-70": "Press de Hombros con Banda",
    "ex-71": "Encogimientos con Mancuernas",
    "ex-72": "Deslizamiento en Pared",
    
    // Biceps
    "ex-7": "Curl con Barra",
    "ex-13": "Curl de Bíceps",
    "ex-73": "Curl Martillo",
    "ex-74": "Curl de Concentración",
    "ex-75": "Curl en Banco Scott",
    "ex-76": "Curl con Cable",
    "ex-77": "Curl Inclinado con Mancuernas",
    "ex-78": "Curl 21s",
    "ex-79": "Curl Araña",
    "ex-80": "Curl Zottman",
    "ex-81": "Curl Bayesián con Cable",
    "ex-82": "Sostenimiento Isométrico de Bíceps",
    "ex-83": "Curl con Banda",
    "ex-84": "Curl de Arrastre",
    
    // Triceps
    "ex-8": "Rompecráneos",
    "ex-14": "Extensión de Tríceps",
    "ex-85": "Pushdown de Tríceps",
    "ex-86": "Extensión de Tríceps sobre la Cabeza",
    "ex-87": "Press de Banca con Agarre Cerrado",
    "ex-88": "Press Francés",
    "ex-89": "Fondos en Banco",
    "ex-90": "Pushdown con Cuerda",
    "ex-91": "Press JM",
    "ex-92": "Patada de Tríceps",
    "ex-93": "Pushdown con Agarre Inverso",
    "ex-94": "Extensión Cruzada",
    "ex-95": "Pushdown con Banda",
    "ex-96": "Extensión Parcial de Tríceps",
    "ex-97": "Apretón Isométrico de Tríceps",
    
    // Forearms
    "ex-139": "Curl de Muñeca",
    "ex-140": "Curl Inverso de Muñeca",
    
    // Legs
    "ex-16": "Curl de Piernas",
    "ex-17": "Extensión de Piernas",
    "ex-9": "Prensa de Piernas",
    "ex-2": "Sentadilla con Barra",
    "ex-98": "Peso Muerto Rumano",
    "ex-99": "Zancada Caminando con Mancuernas",
    "ex-100": "Sentadilla Búlgara",
    "ex-101": "Sentadilla Frontal",
    "ex-102": "Hack Squat",
    "ex-103": "Step-Up con Mancuernas",
    "ex-108": "Sentadilla Sumo",
    "ex-109": "Sentadilla Goblet",
    "ex-110": "Sentadilla Pistol",
    "ex-111": "Sentadilla Isométrica (Wall Sit)",
    "ex-112": "Sentadilla Sissy",
    "ex-113": "Sentadilla Jefferson",
    "ex-114": "Curl de Piernas con Banda",
    "ex-116": "Salto al Caja",
    "ex-150": "Salto Horizontal",
    "ex-151": "Salto con Rodillas al Pecho",
    "ex-152": "Salto de Profundidad",
    "ex-160": "Sentadilla",
    "ex-161": "Step-Up",
    "ex-162": "Zancada",
    
    // Glutes
    "ex-104": "Puente de Glúteos",
    "ex-141": "Hip Thrust con Barra",
    "ex-142": "Patada de Glúteos",
    "ex-143": "Máquina de Abducción",
    "ex-144": "Puente de Glúteos a una Pierna",
    
    // Calves
    "ex-18": "Elevación de Talones",
    "ex-105": "Elevación de Talones Sentado",
    "ex-106": "Elevación de Talones Donkey",
    "ex-107": "Elevación de Talones en Prensa",
    
    // Core
    "ex-20": "Encogimientos Abdominales",
    "ex-15": "Plancha",
    "ex-117": "Giros Rusos",
    "ex-118": "Elevación de Piernas",
    "ex-119": "Leñador (Woodchopper)",
    "ex-120": "Press Pallof",
    "ex-121": "Pájaro-Perro (Bird Dog)",
    "ex-122": "Insecto Muerto (Dead Bug)",
    "ex-123": "Abdominal en Polea",
    "ex-124": "Rueda Abdominal",
    "ex-125": "Patada de Flotador",
    "ex-126": "V-Up",
    "ex-127": "Flexión Lateral",
    "ex-128": "Vacío Abdominal",
    "ex-156": "Elevación de Piernas Colgado",
    "ex-157": "Plancha Lateral",
    "ex-159": "Flexión y Rotación",
    
    // Cardio
    "ex-19": "Correr",
    "ex-115": "Ciclismo (Estático)",
    "ex-129": "Jumping Jacks",
    "ex-131": "Escaladores",
    "ex-135": "Saltar la Cuerda",
    "ex-136": "Escaladora",
    "ex-158": "Rodillas Altas",
    
    // Full Body
    "ex-130": "Burpee",
    "ex-132": "Remo (Máquina)",
    "ex-133": "Battle Rope",
    "ex-134": "Balanceo con Kettlebell",
    "ex-137": "Natación",
    "ex-145": "Turkish Get-Up",
    "ex-146": "Clean & Press con Kettlebell",
    "ex-147": "Snatch con Kettlebell",
    "ex-149": "Lanzamiento de Medicine Ball",
    
    // Mobility
    "ex-138": "Saludo al Sol",
    "ex-153": "Foam Rolling",
    "ex-154": "Estiramiento de Flexores de Cadera",
    "ex-155": "Gato-Vaca",
]

/// Mark: - Localization Helper

/// Get localized exercise name for a given exercise ID
/// - Parameters:
///   - exerciseId: The exercise ID (e.g., "ex-1")
///   - locale: "en" for English (returns original name), "es" for Spanish
///   - defaultName: Fallback name if translation not found
/// - Returns: Localized exercise name
public func localizedExerciseName(for exerciseId: String, locale: String, defaultName: String) -> String {
    guard locale == "es" else { return defaultName }
    return exerciseNamesES[exerciseId] ?? defaultName
}

/// Get all available languages for exercise name localization
public var availableLanguages: [String: String] {
    ["en": "English", "es": "Español"]
}