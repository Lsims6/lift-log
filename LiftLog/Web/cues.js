/* Starting text for each built-in exercise's permanent note: where to feel it, then one or two form points.
   Each one is copied into the note once (see addCues in index.html). After that the note is yours to edit, and
   clearing it doesn't bring the text back. A new exercise added here reaches existing logs the same way. */
const cueText=(mm,form)=>`Mind-muscle: ${mm}\nForm: ${form}`;
window.CUES={
  // quads
  hack:cueText("Quads. Drive through the whole foot and feel your thighs do the work.","Keep your back and hips flat against the pad. Go only as deep as your lower back stays down, and let your knees track over your toes."),
  legpress:cueText("Quads, with glutes helping out of the bottom.","Keep your hips and lower back on the pad at the bottom. Don't snap your knees straight at the top."),
  smithsquat:cueText("Quads and glutes. Think about pushing the floor away.","Set your feet slightly in front of the bar so your heels stay down. Brace your core and keep your chest up."),
  pendulum:cueText("Quads, especially as you come out of the bottom.","Keep your back flat on the pad and press through mid-foot and heel. Lower slowly instead of bouncing at the bottom."),
  goblet:cueText("Quads and glutes, with your core staying tight.","Hold the weight against your chest and keep your elbows inside your knees at the bottom. Chest up, heels down."),
  // glutes
  hipthrust:cueText("Glutes. Squeeze them hard at the top, not your lower back.","Keep your chin tucked and ribs down. Stop when your hips are level with your body, without arching your back."),
  bbhipthrust:cueText("Glutes. Squeeze them hard at the top and pause.","Upper back on the bench, chin tucked, shins vertical at the top. Finish by tucking your pelvis, not arching your back."),
  glutekick:cueText("The glute of the working leg, squeezing at the end of the kick.","Keep your hips square and don't arch your lower back. Stop when the glute is fully squeezed."),
  abductor:cueText("Outer glutes on the sides of your hips.","Sit tall or lean slightly forward, and push out with your knees. Control the pads back in instead of letting the stack drop."),
  // hamstrings
  hamcurl:cueText("Hamstrings. Think about pulling your heels toward your glutes.","Keep your hips on the pad and don't let them rise. Lower slowly."),
  seatedcurl:cueText("Hamstrings, squeezing at the bottom of the curl.","Line your knees up with the machine's pivot and lock the thigh pad down. Sit back against the pad and lower with control."),
  lyingcurl:cueText("Hamstrings, squeezing as your heels come toward your glutes.","Keep your hips pressed into the bench, and don't swing the weight up. Lower slowly."),
  rdl:cueText("Hamstrings stretching on the way down, glutes finishing at the top.","Push your hips straight back with a slight knee bend and a flat back. Keep the bar close to your legs, and stop when your back wants to round."),
  // quads (isolation)
  legext:cueText("Quads, squeezing hard at the top.","Line your knees up with the machine's pivot and hold the handles to stay down in the seat. Lift and lower without swinging."),
  slext:cueText("The quad of the working leg, squeezing at the top.","Line your knee up with the pivot and keep your hips square in the seat. Use a lighter weight and lower slowly."),
  // calves
  calf:cueText("Calves. Press through the ball of your foot and squeeze at the top.","Pause in the stretch at the bottom, then rise as high as you can. Don't bounce."),
  seatedcalf:cueText("The lower calf, under the big muscle you see. Squeeze at the top.","Lock the pad down over your lower thighs. Pause at the bottom instead of bouncing."),
  lpcalf:cueText("Calves, squeezing as you press through the balls of your feet.","Keep only the balls of your feet on the platform and your knees just short of locked. Use a slow, controlled range so your feet can't slip."),
  // back: rows
  rows:cueText("Mid-back and lats. Pull with your elbows, not your hands.","Keep your back flat and your torso steady. Pull toward your lower ribs and squeeze your shoulder blades together."),
  cablerow:cueText("Mid-back and lats, squeezing your shoulder blades together.","Sit tall with your chest up and don't rock back. Pull your elbows past your ribs and let your shoulders stretch forward under control."),
  chestrow:cueText("Mid-back, squeezing your shoulder blades together.","Keep your chest on the pad the whole set. Lead with your elbows and don't shrug."),
  tbar:cueText("Mid-back and lats. Drive your elbows back.","Hinge at the hips with a flat back and keep that angle. Don't heave the weight with your legs or lower back."),
  dbrow:cueText("The lat on the working side. Pull your elbow toward your hip.","Support yourself on the bench with a flat back and square shoulders. Don't twist to lift the weight."),
  // back: pulldowns
  pulldown:cueText("Lats. Drive your elbows down toward your ribs.","Lean back only slightly with your chest up, and pull the bar to your upper chest. Don't pull with your hands or swing."),
  closepd:cueText("Lats, especially low down. Drive your elbows down and back.","Keep your chest up and pull to your upper chest. Let your arms stretch fully at the top under control."),
  machinepd:cueText("Lats. Drive your elbows down toward your ribs.","Set the thigh pad snug and sit tall. Pull your shoulders down first, then your elbows."),
  // lower back
  backext:cueText("Lower back, glutes and hamstrings.","Hinge at the hips and rise until your body is in a straight line. Don't swing or arch past that line."),
  lowbackmachine:cueText("Lower back, working through a slow, smooth squeeze.","Sit with your hips fixed against the seat and move with control. Stop at a comfortable range, and don't throw the weight."),
  goodmorning:cueText("Hamstrings and lower back. Feel the stretch as your hips go back.","Keep the weight light, your back flat and your knees softly bent. Push your hips back and stop before your back rounds."),
  // biceps
  ezbar:cueText("Biceps. Curl with your forearms, keeping your upper arms still.","Keep your elbows at your sides and don't lean back. Lower slowly."),
  machinecurl:cueText("Biceps, squeezing at the top.","Set the seat so your elbows line up with the machine's pivot. Keep your elbows planted and lower slowly."),
  dbcurl:cueText("Biceps. Turn your palms up as you curl and squeeze at the top.","Keep your elbows at your sides and don't swing the weights. Lower slowly."),
  hammercurl:cueText("Biceps and the top of your forearm.","Keep your palms facing each other the whole time. Keep your elbows pinned and don't swing."),
  cablecurl:cueText("Biceps, keeping tension on them the whole way.","Stand tall with your elbows at your sides. Lower with control rather than letting the stack pull your arms down."),
  preacher:cueText("Biceps, especially the stretch near the bottom.","Keep your upper arms on the pad and your shoulders down. Lower slowly, and don't drop into a locked-out elbow."),
  // chest
  bench:cueText("Chest. Think about squeezing your arms together, not just pushing up.","Pull your shoulder blades back and down, feet planted. Lower to mid-chest with elbows about 45° from your body, and don't bounce."),
  inclinebench:cueText("Upper chest, just below your collarbones.","Keep your shoulder blades back and down. Lower to your upper chest with your elbows about 45° from your body."),
  chestpress:cueText("Chest. Bring your upper arms toward each other as you press.","Set the seat so the handles line up with mid-chest. Keep your shoulder blades back against the pad and don't let your shoulders roll forward."),
  dbbench:cueText("Chest, stretching at the bottom and squeezing as your arms come in.","Pull your shoulder blades back and keep your feet planted. Lower with control, wrists stacked over elbows."),
  inclinedb:cueText("Upper chest, stretching at the bottom and squeezing at the top.","Use a low incline and keep your shoulder blades back. Press up and slightly in, without banging the weights."),
  pecdeck:cueText("Chest. Hug a big tree and squeeze your arms together in the middle.","Set the seat so your hands are around chest height. Keep your chest up and shoulder blades back, with a slight bend in your elbows."),
  // shoulders
  shoulder:cueText("Front and side delts, pressing up, not shrugging.","Keep your back against the pad and your ribs down. Press without shrugging your shoulders toward your ears."),
  dbshoulder:cueText("Front and side delts.","Sit tall with your ribs down so your lower back doesn't arch. Press up and slightly in, then lower with control."),
  arnold:cueText("Front and side delts, through the rotation.","Rotate smoothly as you press, not as a jerk. Keep your ribs down and don't arch your back."),
  // side delts
  latraise:cueText("Side delts. Think about pushing the weights out to the walls.","Lift with a slight elbow bend, stopping around shoulder height. Don't shrug or swing."),
  cablelat:cueText("The side delt of the working arm, all the way through the rep.","Lead with your elbow and stop around shoulder height. Stay tall and don't lean away to heave it up."),
  machinelat:cueText("Side delts. Push out with your elbows, not your hands.","Set the seat so your shoulders line up with the pivot. Keep your shoulders down and stop at about shoulder height."),
  // triceps
  pushdown:cueText("Triceps, squeezing hard at the bottom.","Pin your elbows to your sides and only move your forearms. Stand tall, and don't lean over the bar."),
  ohtri:cueText("Triceps, especially the long head stretching behind your head.","Keep your elbows pointing forward and fairly close in. Keep your ribs down so your back doesn't arch."),
  ropepush:cueText("Triceps. Spread the rope apart and squeeze at the bottom.","Pin your elbows to your sides and only move your forearms. Keep the rep smooth, without rocking."),
  dipmachine:cueText("Triceps, with lower chest helping. Squeeze at the bottom of the press.","Stay tall and press straight down with your elbows close to your sides. Keep your shoulders down and don't lock out hard."),
  skull:cueText("Triceps. Only your forearms should move.","Keep your upper arms still with elbows pointing up and fairly close. Lower with control toward your forehead or just behind your head."),
  // cardio
  treadmill:cueText("Glutes and calves on an incline, with your core staying tall.","Stand upright with relaxed shoulders. Avoid hanging on to the rails, so your legs do the work."),
  bike:cueText("Quads and glutes pushing, with hamstrings pulling through.","Set the seat so your knee stays slightly bent at the bottom of the stroke. Keep your hips steady without rocking side to side."),
  rower:cueText("Legs first, then back, then arms.","Drive with your legs, lean back slightly, then pull to your lower ribs. Reverse that order going forward, and keep your back straight."),
  stairs:cueText("Glutes and quads. Push through your whole foot on each step.","Stand tall with a slight forward lean from your hips. Use the rails only for balance, not to hold up your weight."),
  elliptical:cueText("Glutes and quads, pressing through your heels.","Stand tall with your core lightly tight. Keep the motion smooth, and don't lean on the handles."),
  walk:cueText("Glutes pushing you forward, core keeping you tall.","Stand tall with your eyes ahead and relaxed shoulders. Roll from heel to toe and let your arms swing naturally."),
  run:cueText("Glutes and hamstrings pushing you forward, core keeping you tall.","Stay tall with a slight forward lean and relaxed shoulders. Take quick, light steps with your feet landing close under your hips."),
  // abs
  hangcrunch:cueText("Abs. Curl your pelvis up toward your ribs.","Hang without swinging and move slowly. Curl your spine instead of only lifting your knees."),
  wcrunch:cueText("Upper abs. Bring your ribs toward your hips.","Curl your spine rather than yanking your neck. Let the weight stay close and exhale at the top."),
  cablecrunch:cueText("Abs. Bring your ribs toward your hips.","Keep your hips still and curl through your spine, without pulling with your arms. Pause and squeeze at the bottom."),
  abmachine:cueText("Abs. Bring your ribs toward your hips.","Curl through your spine and don't push with your arms or legs. Control the weight back up."),
  legraise:cueText("Lower abs. Curl your pelvis up at the top.","Hang without swinging and lift with control. Tuck your pelvis at the top instead of only raising your legs."),
  // rear delts
  revpecdeck:cueText("Rear delts, at the back of your shoulders.","Keep your chest on the pad and your arms slightly bent. Sweep your arms out wide and don't shrug."),
  facepull:cueText("Rear delts and upper back.","Set the rope at about face height. Pull toward your forehead with your elbows high and your hands apart at the end."),
  reardeltraise:cueText("Rear delts. Think about sweeping your arms out to the walls.","Hinge forward with a flat back and a slight elbow bend. Lift out to the sides without shrugging or swinging."),
  // traps
  kelso:cueText("Mid traps, squeezing your shoulder blades together.","Keep your chest on the pad and your arms straight. Move only your shoulder blades, without pulling with your arms."),
  dbshrug:cueText("Upper traps. Lift your shoulders straight toward your ears.","Keep your arms straight and pause at the top. Don't roll your shoulders."),
  shrugmachine:cueText("Upper traps. Lift your shoulders straight toward your ears.","Stand or sit tall with your arms straight. Pause at the top and lower slowly."),
  // lats
  straightpd:cueText("Lats. Think about pushing the bar down with your armpits.","Hinge slightly with your arms nearly straight. Bring the bar to your thighs with your shoulders staying down."),
  dbpullover:cueText("Lats, stretching as the weight travels behind your head.","Keep a slight fixed bend in your elbows and your ribs down. Go only as far back as your shoulders comfortably allow."),
  machinepullover:cueText("Lats. Drive your upper arms down, with your elbows leading.","Set the seat so your shoulders line up with the pivot. Keep your back on the pad and your hands relaxed."),
};
