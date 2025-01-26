import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:b2win/utils/helper/helper_controller.dart';
import '../../../../../common_widgets/buttons/primary_button.dart';
import '../../../../../constants/sizes.dart';
import '../../../../../constants/text_strings.dart';
import '../../../controllers/signup_controller.dart';

class SignUpFormWidget extends StatelessWidget {
  const SignUpFormWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SignUpController());
    return Container(
      padding: const EdgeInsets.only(top: formHeight - 15, bottom: formHeight),
      child: Form(
        key: controller.signupFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: controller.userName,
              validator: (value) {
                if (value!.isEmpty) return 'Username cannot be empty';
                return null;
              },
              decoration: const InputDecoration(
                  label: Text("Username"),
                  prefixIcon: Icon(LineAwesomeIcons.at)),
            ),
            const SizedBox(height: formHeight - 20),
            TextFormField(
              controller: controller.email,
              validator: Helper.validateEmail,
              decoration: const InputDecoration(
                  label: Text(tEmail),
                  prefixIcon: Icon(LineAwesomeIcons.envelope)),
            ),
            
            const SizedBox(height: formHeight - 20),
            Obx(
              () => TextFormField(
                controller: controller.password,
                validator: Helper.validatePassword,
                obscureText: controller.showPassword.value ? false : true,
                decoration: InputDecoration(
                  label: const Text(tPassword),
                  prefixIcon: const Icon(Icons.fingerprint),
                  suffixIcon: IconButton(
                    icon: controller.showPassword.value
                        ? const Icon(LineAwesomeIcons.eye)
                        : const Icon(LineAwesomeIcons.eye_slash),
                    onPressed: () => controller.showPassword.value =
                        !controller.showPassword.value,
                  ),
                ),
              ),
            ),
            const SizedBox(height: formHeight - 10),
            Obx(
              () => TPrimaryButton(
                isLoading: controller.isLoading.value ? true : false,
                text: tSignup.tr,
                onPressed: controller.isFacebookLoading.value ||
                        controller.isGoogleLoading.value
                    ? () {}
                    : controller.isLoading.value
                        ? () {}
                        : () => controller.createUser(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
