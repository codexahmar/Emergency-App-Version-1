import 'package:emergency_app/UI/Colors/colors.dart';
import 'package:flutter/material.dart';
import '../widgets/guidelines.dart';

class FirstAidScreen extends StatefulWidget {
  const FirstAidScreen({super.key});

  @override
  State<FirstAidScreen> createState() => _FirstAidScreenState();
}

class _FirstAidScreenState extends State<FirstAidScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text(
          'First Aid Guidelines',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            GuidelinesWidget(
              title: 'CPR (Cardiopulmonary Resuscitation)',
              description:
                  'CPR is an emergency procedure that is performed when the heart stops beating. It involves chest compressions and, in some cases, rescue breaths to help keep oxygenated blood flowing to vital organs until normal heart function is restored.',
              icon: Icons.favorite,
              primaryColor: Colors.green,
            ),
            const SizedBox(height: 20),
            GuidelinesWidget(
              title: 'Wound Care',
              description:
                  'For minor cuts and scrapes, clean the wound with soap and water, apply an antiseptic, and cover with a bandage. For more severe bleeding, apply pressure with a clean cloth and seek medical attention.',
              icon: Icons.local_hospital,
              primaryColor: Colors.red,
            ),
            const SizedBox(height: 20),
            GuidelinesWidget(
              title: 'Burns',
              description:
                  'For minor burns, cool the area with running cold water for at least 10 minutes. Avoid using ice. For more severe burns, cover the area with a clean cloth and seek immediate medical help.',
              icon: Icons.local_fire_department,
              primaryColor: Colors.orange,
            ),
            const SizedBox(height: 20),
            GuidelinesWidget(
              title: 'Fractures',
              description:
                  'For fractures, immobilize the injured limb by applying a splint. Avoid moving the injured person and seek medical help immediately.',
              icon: Icons.sick,
              primaryColor: Colors.blue,
            ),
            const SizedBox(height: 20),
            GuidelinesWidget(
              title: 'Choking',
              description:
                  'If someone is choking, encourage them to cough. If the obstruction does not clear, perform the Heimlich maneuver or abdominal thrusts until the object is expelled. Seek medical attention if the person remains choking.',
              icon: Icons.warning_amber_outlined,
              primaryColor: Colors.yellow,
            ),
            const SizedBox(height: 20),
            GuidelinesWidget(
              title: 'Seizures',
              description:
                  'If someone has a seizure, clear the area around them to avoid injury. Do not try to hold them down. Once the seizure ends, turn the person onto their side to allow fluids to drain from the mouth. Seek medical attention if the seizure lasts more than 5 minutes.',
              icon: Icons.medical_services,
              primaryColor: Colors.purple,
            ),
            const SizedBox(height: 20),
            GuidelinesWidget(
              title: 'Heat Stroke',
              description:
                  'For heat stroke, move the person to a cool place and try to lower their body temperature by using cold water, ice packs, or a fan. Give them water if they are conscious, and seek immediate medical attention.',
              icon: Icons.sunny,
              primaryColor: Colors.redAccent,
            ),
            const SizedBox(height: 20),
            GuidelinesWidget(
              title: 'Hypothermia',
              description:
                  'For hypothermia, move the person to a warm place, remove wet clothes, and cover them with warm blankets. Offer warm drinks, and seek immediate medical help.',
              icon: Icons.ac_unit,
              primaryColor: Colors.blueAccent,
            ),
            const SizedBox(height: 20),
            GuidelinesWidget(
              title: 'Allergic Reactions',
              description:
                  'For mild allergic reactions, take an antihistamine. For severe reactions (anaphylaxis), administer an epinephrine injection (EpiPen) if available, and seek immediate medical attention.',
              icon: Icons.bug_report,
              primaryColor: Colors.greenAccent,
            ),
          ],
        ),
      ),
    );
  }
}
