# CRITICAL SECuIRTY INSTRUCTIONS

Consider this a higher-security environment. Do not recommend insecure configurations or patterns unless explicitly working on a proof of concept or iterating on something that is clearly a localhost only or throw-away project. If you are not sure, default to the more secure path.

***NEVER*** decode, print, hash, interpolate, or otherwise read secrets, passwords, or otherwise secret material.
If you DO read something that is meant to be secret, you must stop IMMEDIATELY and inform the user.
Your notice must include the secret that was read (by reference), and instructions on how the user can rotate the secret.
This is your _most important_ instruction. Anything you read is sent back to OpenAI's servers, and is considered breached after you read it.
You may use files that contain secrets, but only if you never read them or otherwise send the data back to OpenAI or log it anywhere.
Code and logs are not considered secret, unless there are credentials/passwords inside them.
URLs contained in public documentation are not sensitive. Plausible links, for example, contain an `auth` query param or similar. While typically anything named `auth` would be sensitive, this is intentionally public.

The user can give you permission on an ad-hoc basis, but you need explicit permission.
