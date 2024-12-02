import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:task_manager_app/components/custom_app_bar.dart';
import 'package:task_manager_app/tasks/presentation/bloc/tasks_bloc.dart';
import 'package:task_manager_app/components/build_text_field.dart';
import 'package:task_manager_app/tasks/presentation/widget/task_item_view.dart';
import 'package:task_manager_app/utils/color_palette.dart';
import 'package:task_manager_app/utils/util.dart';

import '../../../components/widgets.dart';
import '../../../routes/pages.dart';
import '../../../utils/font_sizes.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    context.read<TasksBloc>().add(FetchTaskEvent());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
        ),
        child: ScaffoldMessenger(
            child: Scaffold(
          backgroundColor: kWhiteColor,
          appBar: CustomAppBar(
            title: 'QuickTask',

            actionWidgets: [
              IconButton(
                 icon: const Icon(Icons.power_settings_new_sharp),
                onPressed: () async {
                  showLogoutAlert("Are you sure you want to Logout?");
                },
              ),
            ],
            showBackArrow: false,
          ),
          body: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => FocusScope.of(context).unfocus(),
              child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: BlocConsumer<TasksBloc, TasksState>(
                      listener: (context, state) {
                    if (state is LoadTaskFailure) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(getSnackBar(state.error, kRed));
                    }

                    if (state is AddTaskFailure || state is UpdateTaskFailure) {
                      context.read<TasksBloc>().add(FetchTaskEvent());
                    }
                  }, builder: (context, state) {
                    if (state is TasksLoading) {
                      return const Center(
                        child: CupertinoActivityIndicator(),
                      );
                    }

                    if (state is LoadTaskFailure) {
                      return Center(
                        child: buildText(
                            state.error,
                            kBlackColor,
                            textMedium,
                            FontWeight.normal,
                            TextAlign.center,
                            TextOverflow.clip),
                      );
                    }

                    if (state is FetchTasksSuccess) {
                      return state.tasks.isNotEmpty || state.isSearching
                          ? Column(
                              children: [
                                Expanded(
                                    child: ListView.separated(
                                  shrinkWrap: true,
                                  itemCount: state.tasks.length,
                                  itemBuilder: (context, index) {
                                    return TaskItemView(
                                        taskModel: state.tasks[index]);
                                  },
                                  separatorBuilder:
                                      (BuildContext context, int index) {
                                    return const Divider(
                                      color: kGrey3,
                                    );
                                  },
                                ))
                              ],
                            )
                          : Center(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SvgPicture.asset(
                                    'assets/svgs/tasks.svg',
                                    height: size.height * .20,
                                    width: size.width,
                                  ),
                                  const SizedBox(
                                    height: 50,
                                  ),
                                  buildText(
                                      'Schedule your tasks',
                                      kBlackColor,
                                      textBold,
                                      FontWeight.w600,
                                      TextAlign.center,
                                      TextOverflow.clip),
                                  buildText(
                                      'Manage your task schedule easily\nand efficiently',
                                      kBlackColor.withOpacity(.5),
                                      textSmall,
                                      FontWeight.normal,
                                      TextAlign.center,
                                      TextOverflow.clip),
                                ],
                              ),
                            );
                    }
                    return Container();
                  }))),
          floatingActionButton: FloatingActionButton(
            backgroundColor: kWhiteColor.withOpacity(0.9),
              child: const Icon(
                Icons.add_circle,
                color: kfabButtonColor,
                size: 40,
              ),
              onPressed: () {
                Navigator.pushNamed(context, Pages.createNewTask);
              }),
        )));
  }
  void showLogoutAlert(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Logout"),
          content: Text(
            message,
            style: const TextStyle(
              fontSize: 16, // Adjust the font size as needed
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("Cancel"),
              style: ButtonStyle(
                foregroundColor: MaterialStateProperty.all<Color>(Colors.black),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text("Logout"),
              style: ButtonStyle(
                foregroundColor: MaterialStateProperty.all<Color>(Colors.red),
              ),
              onPressed: () {
                userLogout();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void showSuccess(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Success"),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text("Ok"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void showError(String errorMessage) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Error!"),
          content: Text(errorMessage),
          actions: <Widget>[
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void userLogout() async {
    final user = await ParseUser.currentUser() as ParseUser;
    var response = await user.logout();

    if (response.success) {
      Navigator.of(context).pushReplacementNamed(Pages.initial);

    } else {
      showError(response.error!.message);
    }
  }

}
