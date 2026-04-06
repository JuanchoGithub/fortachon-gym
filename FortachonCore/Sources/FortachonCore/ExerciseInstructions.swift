import Foundation

// MARK: - Exercise Instructions Database
// Ported from old-version/locales/instructions/ - English instructions

/// Returns step-by-step instructions for an exercise by ID.
/// Returns nil if no instructions are available for the given exercise.
public func getExerciseInstructions(for exerciseId: String) -> [String]? {
    return exerciseInstructions[exerciseId]
}

fileprivate let exerciseInstructions: [String: [String]] = [
    // ===== CHEST =====
    "ex-1": [
        "Lie flat on a bench with your feet firmly on the ground.",
        "Grip the barbell with hands slightly wider than shoulder-width apart.",
        "Lower the bar to your mid-chest, keeping your elbows at a 45-degree angle.",
        "Press the bar back up until your arms are fully extended."
    ],
    "ex-11": [
        "Lie on a flat bench with a dumbbell in each hand, palms facing each other.",
        "Press the dumbbells up above your chest with a slight bend in your elbows.",
        "Lower the weights out to your sides in a wide arc, feeling a stretch in your chest.",
        "Keep the slight bend in your elbows throughout the movement.",
        "Bring the dumbbells back together over your chest using your pectoral muscles."
    ],
    "ex-12": [
        "Set an incline bench to a 30-45 degree angle.",
        "Lie on the bench with a dumbbell in each hand at shoulder level, palms facing forward.",
        "Press the dumbbells up until your arms are fully extended, without locking your elbows.",
        "Slowly lower the dumbbells back to the starting position."
    ],
    "ex-21": [
        "Set pulleys to a high position. Grab a handle in each hand.",
        "Take a step forward to create tension. Keep a slight bend in your elbows.",
        "Pull the handles down and across your body in a wide arc.",
        "Squeeze your chest at the peak contraction, then slowly return to the start."
    ],
    "ex-22": [
        "Lie on a decline bench, securing your feet.",
        "Grip the barbell slightly wider than shoulder-width.",
        "Lower the bar to your lower chest, keeping elbows tucked.",
        "Press the bar back up until your arms are fully extended."
    ],
    "ex-23": [
        "Start in a high plank position with hands under your shoulders.",
        "Lower your body until your chest nearly touches the floor.",
        "Keep your body in a straight line from head to heels.",
        "Push back up to the starting position."
    ],
    "ex-24": [
        "Grasp parallel bars with a neutral grip.",
        "Lower your body by bending your elbows, leaning your torso forward to target the chest.",
        "Descend until you feel a stretch in your chest.",
        "Push back up to the starting position, squeezing your chest."
    ],
    "ex-25": [
        "Lie on an incline bench set to 30-45 degrees.",
        "Grip the barbell slightly wider than shoulder-width.",
        "Lower the bar to your upper chest.",
        "Press the bar upwards until your arms are fully extended."
    ],
    "ex-26": [
        "Sit on the machine with your back flat against the pad.",
        "Place your forearms on the padded levers or grab the handles.",
        "Bring the levers together in front of your chest in a controlled arc.",
        "Squeeze your pecs, then slowly return to the start."
    ],
    "ex-27": [
        "Stand tall and hold two small weight plates together between your palms.",
        "Squeeze the plates together forcefully.",
        "Extend your arms straight out in front of you while maintaining pressure.",
        "Slowly bring the plates back to your chest."
    ],
    "ex-28": [
        "Place one end of a barbell into a landmine attachment or a corner.",
        "Lift the other end to your shoulder with one hand.",
        "Press the barbell up and away from you, fully extending your arm.",
        "Lower it back down in a controlled manner."
    ],
    "ex-29": [
        "Place your hands on elevated surfaces like plates or blocks.",
        "Perform a push-up, lowering your chest below your hands for an increased range of motion.",
        "Maintain a straight body line throughout.",
        "Push back to the starting position."
    ],
    "ex-30": [
        "Start in a wide push-up stance.",
        "Shift your weight to one side, lowering your body towards that hand while the other arm straightens.",
        "Push back to the center and repeat on the other side.",
        "This is an advanced unilateral movement."
    ],
    "ex-31": [
        "Adjust the seat so the handles are at mid-chest level.",
        "Grip the handles and press forward until your arms are extended.",
        "Keep your back flat against the pad.",
        "Slowly return to the starting position."
    ],
    "ex-32": [
        "Set pulleys to the lowest position. Grab a handle in each hand.",
        "With a slight bend in the elbows, bring your hands up and together in an arc motion.",
        "Squeeze your upper chest at the top.",
        "Slowly lower back to the start."
    ],
    "ex-33": [
        "Set pulleys to the highest position. Grab a handle in each hand.",
        "Pull the handles down and together in front of your waist.",
        "Focus on squeezing the lower part of your chest.",
        "Return to the starting position in a controlled manner."
    ],
    "ex-34": [
        "Lie on a flat bench holding a weight plate with both hands.",
        "Lower the plate to your chest.",
        "Press the plate straight up until your arms are fully extended.",
        "This can also be done standing (Svend Press)."
    ],
    "ex-35": [
        "Grab suspension trainer handles and assume a push-up position.",
        "The instability will challenge your core and stabilizers.",
        "Perform a push-up by lowering your chest towards the floor.",
        "Press back up to the starting position."
    ],
    "ex-36": [
        "Press your palms together in front of your chest.",
        "Squeeze as hard as you can, creating tension in your pectoral muscles.",
        "Hold the contraction for 10-30 seconds.",
        "This can be done anywhere, without equipment."
    ],
    "ex-37": [
        "Use a lighter weight (40-60% of your 1RM).",
        "Lower the bar to your chest in a controlled manner.",
        "Explosively press the bar up as fast as possible.",
        "Focus on bar speed and explosive power."
    ],

    // ===== BACK =====
    "ex-5": [
        "Bend at the hips with a barbell in hand, keeping your back flat.",
        "Pull the barbell to your lower chest/upper abdomen.",
        "Squeeze your shoulder blades together at the top.",
        "Lower the bar with control.",
        "Keep your core engaged throughout the movement."
    ],
    "ex-10": [
        "Sit at a lat pulldown machine with your thighs secured under the pads.",
        "Grip the bar wider than shoulder-width with an overhand grip.",
        "Pull the bar down to your upper chest, squeezing your shoulder blades together.",
        "Slowly return to the starting position with full lat stretch."
    ],
    "ex-3": [
        "Stand with feet hip-width apart, barbell over mid-foot.",
        "Bend at the hips and knees to grip the bar just outside your knees.",
        "Keep your chest up, back flat, and core tight.",
        "Drive through your heels to stand up with the bar.",
        "Lock out your hips and knees at the top, then lower with control."
    ],
    "ex-6": [
        "Jump up to grab the pull-up bar with an overhand grip, hands shoulder-width apart.",
        "Hang with fully extended arms, engaging your lats.",
        "Pull yourself up until your chin clears the bar.",
        "Lower yourself with control to a full hang position."
    ],
    "ex-38": [
        "Sit on the cable row machine with your feet on the footplates.",
        "Grab the handle with both hands, keeping your back straight.",
        "Pull the handle to your midsection, squeezing your shoulder blades together.",
        "Slowly extend your arms back to the starting position."
    ],
    "ex-39": [
        "Straddle the T-bar with your feet planted firmly.",
        "Hinge at the hips and grab the handles.",
        "Pull the weight to your lower chest, keeping elbows close to your body.",
        "Lower the weight with control."
    ],
    "ex-40": [
        "Place one knee and hand on a bench for support.",
        "Hold a dumbbell in the opposite hand with a neutral grip.",
        "Pull the dumbbell to your hip, keeping your elbow close to your body.",
        "Lower the weight with control and repeat on the other side."
    ],
    "ex-41": [
        "Set a cable pulley to upper chest height with a rope attachment.",
        "Grab the rope with both hands, arms extended.",
        "Pull the rope toward your face, separating the ends and squeezing your rear delts.",
        "Return to the starting position with control."
    ],
    "ex-42": [
        "Hang from a bar with an overhand grip.",
        "Pull your shoulder blades together and bend your elbows.",
        "Pull your chest toward the bar, keeping your body straight.",
        "Lower with control to full arm extension."
    ],
    "ex-43": [
        "Set the barbell in a rack at just below knee height.",
        "Grip the bar with hands just outside shoulder-width.",
        "Drive through your heels and extend your hips to lift the bar.",
        "Lower with control, maintaining a flat back throughout."
    ],
    "ex-44": [
        "Set a cable pulley to upper chest height with a straight bar attachment.",
        "Stand with arms extended, holding the bar with a slight bend in your elbows.",
        "Pull the bar down in an arc motion to your thighs, keeping arms straight.",
        "Return to the starting position with control."
    ],
    "ex-45": [
        "Position yourself on a hyperextension bench with your hips on the pad.",
        "Cross your arms over your chest or hold a weight plate.",
        "Lower your torso until you feel a stretch in your lower back.",
        "Raise your torso back to a neutral position, avoiding hyperextension."
    ],
    "ex-46": [
        "Lie face down on the floor with arms extended overhead.",
        "Simultaneously lift your arms, chest, and legs off the floor.",
        "Hold the contraction for 1-2 seconds.",
        "Lower back to the floor with control."
    ],
    "ex-47": [
        "Hold dumbbells and assume a push-up position.",
        "Row one dumbbell to your hip while maintaining a stable plank.",
        "Lower the dumbbell with control and repeat on the other side.",
        "Engage your core throughout to prevent rotation."
    ],
    "ex-48": [
        "Set the barbell in a landmine attachment or corner.",
        "Stand to the side of the bar and grab the end with one hand.",
        "Pull the bar to your chest, keeping your elbow out to the side.",
        "Lower with control and repeat on the other side."
    ],
    "ex-49": [
        "Set a cable pulley to upper chest height.",
        "Grab the handle with one hand, arm extended.",
        "Pull the handle down and back in an arc, keeping your arm straight.",
        "Return to the starting position with control."
    ],
    "ex-50": [
        "Jump up to grab the pull-up bar with an underhand grip, hands shoulder-width apart.",
        "Hang with fully extended arms, engaging your lats and biceps.",
        "Pull yourself up until your chin clears the bar.",
        "Lower yourself with control to a full hang position."
    ],
    "ex-51": [
        "Stand with feet shoulder-width apart, holding dumbbells at your sides.",
        "Keep your back straight and core engaged.",
        "Shrug your shoulders up toward your ears, squeezing your traps.",
        "Lower the weights back to the starting position with control."
    ],
    "ex-52": [
        "Sit at a lat pulldown machine with an underhand grip.",
        "Pull the bar down to your upper chest, engaging your biceps and lats.",
        "Squeeze your shoulder blades together at the bottom.",
        "Slowly return to the starting position."
    ],
    "ex-53": [
        "Hold a resistance band with both hands at chest height, arms extended.",
        "Pull the band apart by moving your hands out to the sides.",
        "Squeeze your shoulder blades together at full extension.",
        "Return to the starting position with control."
    ],
    "ex-54": [
        "Hold heavy dumbbells or kettlebells at your sides.",
        "Stand tall with your shoulders back and core engaged.",
        "Walk for the prescribed distance or time, maintaining good posture.",
        "Keep your grip tight and avoid leaning to either side."
    ],
    "ex-55": [
        "Place a barbell across your upper back, like a squat position.",
        "Hinge at the hips, lowering your torso until nearly parallel to the floor.",
        "Drive through your heels to return to the starting position.",
        "Keep your core tight and back flat throughout the movement."
    ],
    "ex-148": [
        "Place a kettlebell on the floor between your feet.",
        "Hinge at your hips and grasp the kettlebell with one hand.",
        "Explosively pull the kettlebell up to shoulder height.",
        "Lower with control and repeat on the other side."
    ],

    // ===== SHOULDERS =====
    "ex-4": [
        "Stand with feet shoulder-width apart, barbell at shoulder height.",
        "Press the barbell overhead until arms are fully extended.",
        "Keep your core tight and avoid arching your back.",
        "Lower the barbell back to shoulder height with control."
    ],
    "ex-56": [
        "Stand with feet shoulder-width apart, dumbbells at your sides.",
        "Raise the dumbbells out to the sides until they reach shoulder height.",
        "Keep a slight bend in your elbows throughout the movement.",
        "Lower the dumbbells with control, avoiding swinging."
    ],
    "ex-57": [
        "Stand with feet shoulder-width apart, dumbbells in front of your thighs.",
        "Raise one or both dumbbells in front of you to shoulder height.",
        "Keep your arms straight with a slight bend in the elbows.",
        "Lower the dumbbells with control."
    ],
    "ex-58": [
        "Bend forward at the hips with dumbbells hanging at your sides.",
        "Raise the dumbbells out to the sides, squeezing your rear delts.",
        "Keep a slight bend in your elbows throughout.",
        "Lower with control, avoiding momentum."
    ],
    "ex-59": [
        "Stand with feet shoulder-width apart, barbell in front of your thighs.",
        "Pull the bar straight up along your body to shoulder height.",
        "Keep your elbows high and close to your body.",
        "Lower the bar with control."
    ],
    "ex-60": [
        "Sit on a bench with dumbbells at shoulder height, palms facing in.",
        "Press the dumbbells up while rotating your palms to face forward.",
        "Fully extend your arms overhead.",
        "Reverse the motion to return to the starting position."
    ],
    "ex-61": [
        "Stand sideways to a cable machine with the handle at your side.",
        "Raise the handle out to the side until it reaches shoulder height.",
        "Keep a slight bend in your elbow throughout.",
        "Lower with control and repeat on the other side."
    ],
    "ex-62": [
        "Start in a push-up position, then walk your feet toward your hands.",
        "Your hips should be elevated, forming an inverted V.",
        "Lower your head toward the floor by bending your elbows.",
        "Press back up to the starting position."
    ],
    "ex-63": [
        "Kick up into a handstand against a wall or freestanding.",
        "Lower your head toward the floor by bending your elbows.",
        "Press back up to full arm extension.",
        "This is an advanced movement — build up gradually."
    ],
    "ex-64": [
        "Stand with dumbbells at your sides, leaning slightly away from the working side.",
        "Raise the dumbbell out to the side to shoulder height.",
        "The lean increases tension on the side delt throughout.",
        "Lower with control."
    ],
    "ex-65": [
        "Bend forward at the hips with dumbbells hanging at your sides.",
        "Raise the dumbbells up and out in a Y shape (45 degrees from your body).",
        "Squeeze your shoulders at the top of the movement.",
        "Lower with control."
    ],
    "ex-66": [
        "Hold dumbbells at your sides with elbows bent at 90 degrees.",
        "Externally rotate your shoulders, pulling the dumbbells outward.",
        "Return to the starting position with control.",
        "This targets the rotator cuff muscles."
    ],
    "ex-67": [
        "Sit on the machine with your back flat against the pad.",
        "Grip the handles at shoulder height.",
        "Press the handles up until your arms are fully extended.",
        "Lower with control to the starting position."
    ],
    "ex-68": [
        "Sit on a bench with back support, barbell behind your head.",
        "Press the barbell overhead until arms are fully extended.",
        "Lower the barbell back behind your head with control.",
        "Ensure shoulder mobility before attempting this exercise."
    ],
    "ex-69": [
        "Hold a weight plate with both hands at waist height.",
        "Raise the plate in front of you to shoulder height.",
        "Keep your arms straight and core engaged.",
        "Lower the plate with control."
    ],
    "ex-70": [
        "Stand on a resistance band with handles at shoulder height.",
        "Press the handles overhead until arms are fully extended.",
        "Keep your core tight and avoid leaning.",
        "Lower with control to the starting position."
    ],
    "ex-71": [
        "Stand with feet shoulder-width apart, dumbbells at your sides.",
        "Shrug your shoulders up toward your ears, squeezing your traps.",
        "Hold the contraction briefly at the top.",
        "Lower the dumbbells with control."
    ],
    "ex-72": [
        "Stand with your back against a wall, arms bent at 90 degrees.",
        "Slide your arms up the wall while keeping contact with elbows and wrists.",
        "Return to the starting position with control.",
        "This improves shoulder mobility and stability."
    ],

    // ===== BICEPS =====
    "ex-7": [
        "Stand with feet shoulder-width apart, holding a barbell with an underhand grip.",
        "Keep your elbows close to your sides.",
        "Curl the bar up toward your shoulders, squeezing your biceps.",
        "Lower the bar with control to full arm extension."
    ],
    "ex-13": [
        "Stand with feet shoulder-width apart, dumbbells at your sides.",
        "Keep your elbows close to your sides.",
        "Curl the dumbbells up toward your shoulders.",
        "Lower with control to full arm extension."
    ],
    "ex-73": [
        "Stand with dumbbells at your sides, palms facing each other (neutral grip).",
        "Curl the dumbbells up toward your shoulders.",
        "Keep your wrists straight and elbows close to your sides.",
        "Lower with control."
    ],
    "ex-74": [
        "Sit on a bench and rest your elbow against your inner thigh.",
        "Curl the dumbbell up toward your shoulder.",
        "Squeeze your bicep hard at the top of the movement.",
        "Lower with control to full extension."
    ],
    "ex-75": [
        "Sit at a preacher curl bench with your armpit over the top of the pad.",
        "Hold a barbell or dumbbell with an underhand grip.",
        "Curl the weight up, keeping your upper arm against the pad.",
        "Lower with control to near full extension."
    ],
    "ex-76": [
        "Stand facing a cable machine with a handle attachment.",
        "Keep your elbow close to your side.",
        "Curl the handle up toward your shoulder.",
        "Lower with control, maintaining tension throughout."
    ],
    "ex-77": [
        "Sit on an incline bench with dumbbells hanging at your sides.",
        "Keep your elbows pointed down and close to your body.",
        "Curl the dumbbells up toward your shoulders.",
        "Lower with control to full stretch."
    ],
    "ex-78": [
        "Perform 7 reps in the bottom half of the curl.",
        "Perform 7 reps in the top half of the curl.",
        "Perform 7 full-range reps.",
        "This creates significant metabolic stress for growth."
    ],
    "ex-79": [
        "Lie face down on an incline bench with arms hanging.",
        "Curl the barbell or dumbbells up toward your shoulders.",
        "The position isolates the biceps by preventing body momentum.",
        "Squeeze at the top and lower with control."
    ],
    "ex-80": [
        "Stand with dumbbells at your sides.",
        "Curl up with palms facing up (supinated grip).",
        "At the top, rotate to palms facing down (pronated grip).",
        "Lower with control. Hit both biceps and forearms."
    ],
    "ex-81": [
        "Stand between two low cable pulleys.",
        "Grab the handles with palms facing forward, stepping forward for tension.",
        "Curl the handles up, keeping elbows behind the cable line.",
        "Lower with control, feeling a deep stretch."
    ],
    "ex-82": [
        "Curl a dumbbell or barbell to a 90-degree angle.",
        "Hold the position isometrically for 10-30 seconds.",
        "Keep constant tension in the biceps throughout the hold.",
        "Focus on squeezing the biceps hard."
    ],
    "ex-83": [
        "Stand on a resistance band with handles in each hand.",
        "Curl the handles up toward your shoulders.",
        "Keep your elbows close to your sides.",
        "Lower with control, maintaining band tension."
    ],
    "ex-84": [
        "Stand with a barbell, pulling the bar up along your body.",
        "Your elbows should travel behind your torso.",
        "Squeeze your biceps at the top.",
        "Lower with control."
    ],

    // ===== TRICEPS =====
    "ex-8": [
        "Lie on a bench holding a barbell with a narrow grip above your head.",
        "Lower the bar by bending your elbows, keeping upper arms stationary.",
        "Bring the bar down to just above your forehead.",
        "Extend your arms back to the starting position."
    ],
    "ex-14": [
        "Stand facing a cable machine with a rope or bar attachment.",
        "Keep your elbows tucked at your sides.",
        "Extend your arms down until fully straightened.",
        "Return to the starting position with control."
    ],
    "ex-85": [
        "Stand facing a cable machine with a bar or rope attachment.",
        "Keep your elbows pinned to your sides.",
        "Push the attachment down until your arms are fully extended.",
        "Return to the starting position with control."
    ],
    "ex-86": [
        "Hold a dumbbell with both hands overhead.",
        "Lower the dumbbell behind your head by bending your elbows.",
        "Keep your upper arms close to your head.",
        "Extend your arms back to the starting position."
    ],
    "ex-87": [
        "Lie on a bench, gripping the barbell with hands narrower than shoulder-width.",
        "Lower the bar to your lower chest, keeping your elbows tucked.",
        "Press the bar back up to full arm extension.",
        "This targets the triceps more than a standard bench press."
    ],
    "ex-88": [
        "Hold a barbell overhead with both hands.",
        "Lower the barbell behind your head by bending your elbows.",
        "Keep your upper arms stationary and close to your head.",
        "Extend your arms back to full extension."
    ],
    "ex-89": [
        "Sit on a bench with your hands gripping the edge beside your hips.",
        "Walk your feet out, extending your legs.",
        "Lower your body by bending your elbows to about 90 degrees.",
        "Push back up to the starting position."
    ],
    "ex-90": [
        "Attach a rope to a high cable pulley.",
        "Keep your elbows pinned to your sides.",
        "Pull the rope down, spreading the ends apart at the bottom.",
        "Return to the starting position with control."
    ],
    "ex-91": [
        "Lie on a bench with a barbell positioned between a skull crusher and bench press grip.",
        "Lower the bar to your upper chest/neck area.",
        "Press the bar back up, engaging both triceps and chest.",
        "This hybrid movement maximizes tricep activation."
    ],
    "ex-92": [
        "Bend forward at the hips with a dumbbell in one hand.",
        "Keep your elbow tucked and extend your arm behind you.",
        "Squeeze your tricep hard at full extension.",
        "Lower with control and repeat on the other side."
    ],
    "ex-93": [
        "Face a cable machine with an underhand grip on the attachment.",
        "Keep your elbows pinned to your sides.",
        "Push the attachment down until fully extended.",
        "Return to the starting position with control."
    ],
    "ex-94": [
        "Stand with a dumbbell in each hand at your sides.",
        "Extend one arm across your body while keeping the elbow pinned.",
        "Return to the starting position and repeat on the other side.",
        "This targets the lateral head of the triceps."
    ],
    "ex-95": [
        "Attach a resistance band to a high anchor point.",
        "Keep your elbows pinned to your sides.",
        "Push the band down until your arms are fully extended.",
        "Return to the starting position with control."
    ],
    "ex-96": [
        "Use a cable machine with a light weight.",
        "Perform partial reps in the top half of the extension.",
        "This emphasizes the lockout portion of the movement.",
        "Focus on squeezing the triceps throughout."
    ],
    "ex-97": [
        "Extend your arms to about halfway.",
        "Hold the isometric contraction for 10-30 seconds.",
        "Keep constant tension in the triceps throughout the hold.",
        "Focus on squeezing the triceps hard."
    ],

    // ===== FOREARMS =====
    "ex-139": [
        "Sit on a bench with your forearms resting on your thighs, palms facing up.",
        "Hold dumbbells with your wrists extending over your knees.",
        "Curl your wrists up as far as possible, squeezing your forearms.",
        "Lower with control to full wrist extension."
    ],
    "ex-140": [
        "Sit on a bench with your forearms resting on your thighs, palms facing down.",
        "Hold dumbbells with your wrists extending over your knees.",
        "Extend your wrists up as far as possible.",
        "Lower with control to full wrist flexion."
    ],

    // ===== LEGS =====
    "ex-16": [
        "Sit on the leg curl machine with your legs extended.",
        "Position the pad against your lower calves, just above the ankles.",
        "Curl your legs up by bending your knees.",
        "Lower with control to near full extension."
    ],
    "ex-17": [
        "Sit on the leg extension machine with your back flat against the pad.",
        "Position the pad against your lower shins, just above the ankles.",
        "Extend your legs until fully straightened.",
        "Lower with control, avoiding locking out completely."
    ],
    "ex-9": [
        "Sit on the leg press machine with your back flat against the pad.",
        "Place your feet shoulder-width apart on the platform.",
        "Lower the platform by bending your knees to about 90 degrees.",
        "Push through your heels to return to the starting position."
    ],
    "ex-2": [
        "Stand with feet shoulder-width apart, barbell on your upper back.",
        "Lower your body by bending your knees and hips.",
        "Descend until your thighs are at least parallel to the floor.",
        "Drive through your heels to return to the starting position."
    ],
    "ex-98": [
        "Stand with feet hip-width apart, barbell in your hands.",
        "Hinge at the hips, lowering the barbell along your legs.",
        "Feel the stretch in your hamstrings as you descend.",
        "Drive through your heels to return to the starting position."
    ],
    "ex-99": [
        "Hold dumbbells at your sides and step forward with one leg.",
        "Lower your back knee toward the floor.",
        "Push through your front heel to step forward with the other leg.",
        "Alternate legs for the prescribed reps."
    ],
    "ex-100": [
        "Stand a few feet in front of a bench, facing away.",
        "Place one foot on the bench behind you.",
        "Lower your body by bending your front knee and hip.",
        "Push through your front heel to return to the starting position."
    ],
    "ex-101": [
        "Stand with the barbell resting on your front delts and clavicles.",
        "Keep your elbows high and core tight.",
        "Lower your body until your thighs are parallel to the floor.",
        "Drive through your heels to return to the starting position."
    ],
    "ex-102": [
        "Stand on the hack squat machine with your back flat against the pad.",
        "Position your feet shoulder-width apart on the platform.",
        "Lower the platform by bending your knees.",
        "Push through your heels to return to the starting position."
    ],
    "ex-103": [
        "Hold dumbbells at your sides and stand in front of a bench.",
        "Step up onto the bench with one foot.",
        "Drive through your heel to lift your body up.",
        "Step down with control and repeat on the other side."
    ],
    "ex-108": [
        "Stand with feet wider than shoulder-width apart, toes pointed out.",
        "Hold a dumbbell with both hands at chest height.",
        "Lower your body until your thighs are parallel to the floor.",
        "Push through your heels to return to the starting position."
    ],
    "ex-109": [
        "Hold a dumbbell vertically at chest height with both hands.",
        "Stand with feet shoulder-width apart.",
        "Lower your body until your thighs are parallel to the floor.",
        "Drive through your heels to return to the starting position."
    ],
    "ex-110": [
        "Stand on one leg with the other leg extended in front of you.",
        "Lower your body by bending your standing knee until your thigh is parallel.",
        "Keep your extended leg straight throughout.",
        "Push through your heel to return to the starting position."
    ],
    "ex-111": [
        "Stand with your back flat against a wall.",
        "Slide down until your thighs are parallel to the floor.",
        "Hold the position for the prescribed time.",
        "Keep your knees at 90 degrees and weight on your heels."
    ],
    "ex-112": [
        "Stand with feet shoulder-width apart, hands behind your head.",
        "Lower your body by bending your knees while leaning forward.",
        "Your hips will move forward as you descend, placing load on the quads.",
        "Return to the starting position using your quads."
    ],
    "ex-113": [
        "Place a barbell on the floor, standing to one side of the center.",
        "Straddle the bar and grip it with both hands.",
        "Drive through your feet to lift the bar off the floor.",
        "Lower with control."
    ],
    "ex-114": [
        "Attach a resistance band to a low anchor point.",
        "Loop the other end around your ankle.",
        "Curl your heel toward your glutes against the resistance.",
        "Lower with control."
    ],
    "ex-116": [
        "Stand in front of a box or platform.",
        "Squat down and explosively jump onto the box.",
        "Land softly with knees bent.",
        "Step down and repeat."
    ],
    "ex-150": [
        "Stand with feet shoulder-width apart.",
        "Squat down and explosively jump forward as far as possible.",
        "Land softly with knees bent.",
        "Reset and repeat."
    ],
    "ex-151": [
        "Stand with feet shoulder-width apart.",
        "Explosively jump up, bringing your knees to your chest.",
        "Land softly with knees bent.",
        "Reset and repeat."
    ],
    "ex-152": [
        "Stand on an elevated platform or box.",
        "Step off and land with knees slightly bent.",
        "Immediately jump as high as possible upon landing.",
        "Absorb the impact through your legs."
    ],
    "ex-160": [
        "Stand with feet shoulder-width apart.",
        "Lower your body by bending your knees and hips.",
        "Descend until your thighs are at least parallel to the floor.",
        "Drive through your heels to return to the starting position."
    ],
    "ex-161": [
        "Stand in front of a bench or step.",
        "Step up with one foot, driving through your heel.",
        "Bring your other foot up to meet it.",
        "Step down with control and repeat on the other side."
    ],
    "ex-162": [
        "Stand with feet hip-width apart.",
        "Step forward with one leg and lower your back knee toward the floor.",
        "Push through your front heel to return to the starting position.",
        "Alternate legs for the prescribed reps."
    ],

    // ===== GLUTES =====
    "ex-104": [
        "Lie on your back with knees bent and feet flat on the floor.",
        "Drive through your heels to lift your hips off the floor.",
        "Squeeze your glutes at the top of the movement.",
        "Lower with control to the starting position."
    ],
    "ex-141": [
        "Sit with your upper back against a bench, barbell across your hips.",
        "Plant your feet flat on the floor, shoulder-width apart.",
        "Drive through your heels to lift your hips up.",
        "Squeeze your glutes at the top and lower with control."
    ],
    "ex-142": [
        "Attach a cable to your ankle and face the machine.",
        "Keep your leg slightly bent and kick your heel back and up.",
        "Squeeze your glute hard at the top of the movement.",
        "Lower with control and repeat on the other side."
    ],
    "ex-143": [
        "Sit on the hip abduction machine with your back against the pad.",
        "Place your legs against the inner pads.",
        "Push your legs out to the sides against the resistance.",
        "Return to the starting position with control."
    ],
    "ex-144": [
        "Lie on your back with one knee bent and the other leg extended.",
        "Drive through the heel of the bent leg to lift your hips.",
        "Squeeze your glute at the top of the movement.",
        "Lower with control and repeat on the other side."
    ],

    // ===== CALVES =====
    "ex-18": [
        "Stand on the calf raise machine with your shoulders under the pads.",
        "Position the balls of your feet on the platform.",
        "Raise up onto your toes as high as possible.",
        "Lower your heels below the platform level for a full stretch."
    ],
    "ex-105": [
        "Sit on the calf raise machine with the pad on your thighs.",
        "Position the balls of your feet on the platform.",
        "Raise up onto your toes as high as possible.",
        "Lower with control for a full stretch of the soleus."
    ],
    "ex-106": [
        "Position yourself in the donkey calf raise machine.",
        "Place the balls of your feet on the platform.",
        "Raise up onto your toes as high as possible.",
        "Lower your heels below the platform for a deep stretch."
    ],
    "ex-107": [
        "Sit on the leg press machine with only the balls of your feet on the platform.",
        "Press the platform up by extending your ankles.",
        "Hold the contraction briefly at the top.",
        "Lower with control to a full calf stretch."
    ],

    // ===== CORE =====
    "ex-20": [
        "Lie on your back with knees bent and feet flat on the floor.",
        "Place your hands behind your head or across your chest.",
        "Curl your shoulders off the floor, squeezing your abs.",
        "Lower back to the starting position with control."
    ],
    "ex-15": [
        "Start in a push-up position on your forearms.",
        "Keep your body in a straight line from head to heels.",
        "Engage your core and hold the position for the prescribed time.",
        "Avoid letting your hips sag or pike up."
    ],
    "ex-117": [
        "Sit on the floor with knees bent, holding a dumbbell at your chest.",
        "Lean back slightly and lift your feet off the floor (optional).",
        "Rotate your torso from side to side, touching the weight to the floor each side.",
        "Keep your core engaged throughout."
    ],
    "ex-118": [
        "Lie on your back with legs extended and hands at your sides.",
        "Keeping your legs straight, lift them up toward the ceiling.",
        "Lower your legs with control, stopping just above the floor.",
        "Keep your lower back pressed to the floor throughout."
    ],
    "ex-119": [
        "Stand sideways to a cable machine with a handle attachment.",
        "Hold the handle with both hands at chest height.",
        "Rotate your torso across your body, pulling the cable.",
        "Return to the starting position with control. Repeat on the other side."
    ],
    "ex-120": [
        "Stand sideways to a cable machine with the handle at chest height.",
        "Hold the handle with both hands at your sternum.",
        "Press the handle straight out in front of you, resisting rotation.",
        "Return with control. Repeat on the other side."
    ],
    "ex-121": [
        "Start on all fours with hands under shoulders and knees under hips.",
        "Simultaneously extend one arm forward and the opposite leg backward.",
        "Hold for 2-3 seconds, keeping your core engaged.",
        "Return to the start and repeat on the other side."
    ],
    "ex-122": [
        "Lie on your back with knees bent at 90 degrees and arms extended.",
        "Simultaneously lower one arm and the opposite leg toward the floor.",
        "Keep your core engaged and lower back pressed to the floor.",
        "Return to the start and repeat on the other side."
    ],
    "ex-123": [
        "Kneel in front of a cable machine with a rope attachment.",
        "Hold the rope behind your head with both hands.",
        "Crunch down by contracting your abs, bringing your elbows toward your thighs.",
        "Return to the starting position with control."
    ],
    "ex-124": [
        "Kneel on the floor with an ab wheel in front of you.",
        "Grab the wheel and slowly roll forward, extending your body.",
        "Keep your core tight and avoid letting your hips sag.",
        "Pull yourself back to the starting position."
    ],
    "ex-125": [
        "Lie on your back with legs extended and hands under your glutes.",
        "Lift your legs a few inches off the floor.",
        "Alternately kick each leg up and down in a fluttering motion.",
        "Keep your core engaged and lower back pressed to the floor."
    ],
    "ex-126": [
        "Lie on your back with legs extended and arms overhead.",
        "Simultaneously raise your legs and torso to touch your hands to your feet.",
        "Contract your abs hard at the top of the movement.",
        "Lower back to the starting position with control."
    ],
    "ex-127": [
        "Stand with feet shoulder-width apart, dumbbell in one hand.",
        "Bend to the side, lowering the dumbbell toward your knee.",
        "Return to the standing position and repeat on the same side.",
        "Switch sides after completing your reps."
    ],
    "ex-128": [
        "Sit or stand with your back straight.",
        "Exhale fully and contract your transverse abdominis.",
        "Pull your belly button in toward your spine as hard as possible.",
        "Hold the contraction for 10-30 seconds while breathing normally."
    ],
    "ex-156": [
        "Hang from a pull-up bar with an overhand grip.",
        "Keeping your legs straight, raise them until parallel to the floor.",
        "Lower your legs with control, avoiding swinging.",
        "Keep your core engaged throughout the movement."
    ],
    "ex-157": [
        "Start in a side plank position on your forearm.",
        "Stack your feet and keep your body in a straight line.",
        "Hold the position for the prescribed time.",
        "Switch sides and repeat."
    ],
    "ex-159": [
        "Start in a push-up position.",
        "Perform a push-up, then rotate into a side plank on one side.",
        "Return to the center and perform another push-up.",
        "Rotate to the other side. Continue alternating sides."
    ],

    // ===== CARDIO =====
    "ex-19": [
        "Maintain a steady pace for the prescribed duration or distance.",
        "Keep your breathing rhythmic and your posture upright.",
        "Warm up for 5 minutes before starting your main set.",
        "Cool down with 5 minutes of walking after your run."
    ],
    "ex-115": [
        "Adjust the seat and handlebars to a comfortable height.",
        "Maintain a steady cadence for the prescribed duration.",
        "Keep your core engaged and avoid leaning on the handlebars.",
        "Cool down with 5 minutes of easy pedaling."
    ],
    "ex-129": [
        "Stand with feet together and arms at your sides.",
        "Jump, spreading your feet wide while bringing your arms overhead.",
        "Jump again, returning to the starting position.",
        "Maintain a steady rhythm for the prescribed duration."
    ],
    "ex-131": [
        "Start in a high plank position.",
        "Drive one knee toward your chest, then quickly switch legs.",
        "Continue alternating legs at a rapid pace.",
        "Keep your core engaged and hips level throughout."
    ],
    "ex-135": [
        "Hold the rope handles with your arms at your sides.",
        "Turn the rope using your wrists, jumping over the rope each rotation.",
        "Stay on the balls of your feet with knees slightly bent.",
        "Maintain a steady rhythm for the prescribed duration."
    ],
    "ex-136": [
        "Stand on the stair climber with your feet on the steps.",
        "Step up at a steady, controlled pace.",
        "Maintain good posture and avoid leaning on the rails.",
        "Adjust the resistance or speed as needed."
    ],
    "ex-158": [
        "Stand with feet hip-width apart.",
        "Drive your knees up toward your chest as high as possible.",
        "Pump your arms as if jogging in place.",
        "Maintain a rapid pace for the prescribed duration."
    ],

    // ===== FULL BODY =====
    "ex-130": [
        "Start standing, then squat down and place your hands on the floor.",
        "Kick your feet back into a push-up position.",
        "Perform a push-up, then jump your feet back to your hands.",
        "Jump explosively upward, reaching your arms overhead."
    ],
    "ex-132": [
        "Sit on the rowing machine with feet secured in the foot straps.",
        "Push with your legs first, then lean back and pull with your arms.",
        "Reverse the sequence: arms, lean forward, legs to return.",
        "Maintain a steady, rhythmic pace."
    ],
    "ex-133": [
        "Hold one end of each battle rope in both hands.",
        "Create alternating waves by moving your arms up and down.",
        "Keep your core engaged and knees slightly bent.",
        "Maintain a steady rhythm for the prescribed duration."
    ],
    "ex-134": [
        "Stand with feet shoulder-width apart, kettlebell on the floor.",
        "Hinge at the hips and swing the kettlebell between your legs.",
        "Drive through your hips to swing the kettlebell up to shoulder height.",
        "Let the kettlebell swing back between your legs and repeat."
    ],
    "ex-137": [
        "Swim at a steady pace for the prescribed duration or distance.",
        "Focus on proper stroke technique and breathing.",
        "Warm up with 5 minutes of easy swimming.",
        "Cool down with 5 minutes of easy swimming."
    ],
    "ex-145": [
        "Start with the kettlebell in a rack position at one shoulder.",
        "Press the kettlebell overhead and stabilize.",
        "Step back and lower into a lunge, keeping the bell overhead.",
        "Continue through the movement sequence to a standing position."
    ],
    "ex-146": [
        "Place the kettlebell on the floor between your feet.",
        "Clean the kettlebell to your shoulder in one smooth motion.",
        "Press the kettlebell overhead to full arm extension.",
        "Lower with control and repeat."
    ],
    "ex-147": [
        "Place the kettlebell on the floor between your feet.",
        "Explosively pull the kettlebell up in one arc overhead.",
        "Lock out your arm at the top of the movement.",
        "Lower with control and alternate arms."
    ],
    "ex-149": [
        "Hold a medicine ball overhead with both hands.",
        "Reach up tall and explosively throw the ball to the ground.",
        "Catch the ball on the bounce or reset.",
        "Engage your core and lats throughout the slam."
    ],

    // ===== MOBILITY =====
    "ex-138": [
        "Start standing at the front of your mat.",
        "Flow through mountain pose, forward fold, plank, cobra, and downward dog.",
        "Hold each position for 1-3 breaths.",
        "Repeat the sequence for the prescribed duration."
    ],
    "ex-153": [
        "Place a foam roller on the floor under the target muscle group.",
        "Slowly roll back and forth, pausing on tender spots.",
        "Apply gradual pressure, allowing the muscle to release.",
        "Spend 30-60 seconds per muscle group."
    ],
    "ex-154": [
        "Kneel on one knee with the opposite foot in front.",
        "Push your hips forward, feeling a stretch in the front of your hip.",
        "Hold the stretch for 20-30 seconds.",
        "Switch sides and repeat."
    ],
    "ex-155": [
        "Start on all fours with hands under shoulders and knees under hips.",
        "Inhale, arching your back and looking up (Cow Pose).",
        "Exhale, rounding your spine and tucking your chin (Cat Pose).",
        "Flow between the two positions for 10-15 reps."
    ],
]