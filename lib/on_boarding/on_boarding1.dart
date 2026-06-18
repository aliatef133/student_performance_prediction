
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../signIn/signIn.dart';
import 'on_baording_item.dart';
import 'on_boarding_model.dart';

class Onboarding extends StatefulWidget {
  const Onboarding({super.key});

  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> {
  var controller = PageController();
  var activeIndex = 0;

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xffFFFFFF),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: size.width * 0.08),
          child: Column(
            children: [
              SizedBox(height: size.height * 0.05),

              Expanded(
                child: PageView.builder(
                  controller: controller,
                  onPageChanged: (int index) {
                    setState(() {
                      activeIndex = index;
                    });
                  },
                  itemCount: OnboardingModel.OnboardingList.length,
                  itemBuilder: (context, int index) {
                    var onboardingModel =
                    OnboardingModel.OnboardingList[index];
                    return OnboardingItem(onboardingModel: onboardingModel);
                  },
                ),
              ),

              const SizedBox(height: 20),


              SmoothPageIndicator(
                controller: controller,
                count: OnboardingModel.OnboardingList.length,
                effect: const ExpandingDotsEffect(
                  activeDotColor: Color(0xFFF5669FF),
                  dotColor: Colors.black12,
                  dotHeight: 8,
                  dotWidth: 8,
                  expansionFactor: 3,
                  spacing: 6,
                ),
              ),

              const SizedBox(height: 30),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(size.width * 0.6, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  backgroundColor: Color(0xFFF5669FF),
                ),
                onPressed: () {
                  if (activeIndex ==
                      OnboardingModel.OnboardingList.length - 1) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const SignIn()),
                    );
                  } else {
                    controller.nextPage(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut);
                  }
                },
                child: const Text(
                  "Next",
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
              ),

              const SizedBox(height: 15),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const SignIn()),
                      );
                    },
                    child: const Text(
                      "Skip",
                      style: TextStyle(color: Color(0xff5669FF), fontSize: 20),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      if (activeIndex !=
                          OnboardingModel.OnboardingList.length - 1) {
                        controller.nextPage(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut);
                      } else {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SignIn()),
                        );
                      }
                    },
                    icon: const Icon(Icons.arrow_forward,
                        color: Color(0xFFF5669FF), size: 30),
                  ),
                ],
              ),

              const SizedBox(height: 22),
            ],
          ),
        ),
      ),
    );
  }
}
