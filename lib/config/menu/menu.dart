import 'rive_model.dart';

class Menu {
  final String title;
  final RiveModel rive;

  Menu({required this.title, required this.rive});
}

//se define el menu lateral
List<Menu> sidebarMenus = [
  Menu(
    title: "Inicio",
    rive: RiveModel(
      src: "assets/RiveAssets/icons.riv",
      artboard: "HOME",
      stateMachineName: "HOME_interactivity",
    ),
  ),
  Menu(
    title: "Mis Programas",
    rive: RiveModel(
      src: "assets/RiveAssets/icons.riv",
      artboard: "SEARCH",
      stateMachineName: "SEARCH_Interactivity",
    ),
  ),
  Menu(
    title: "Curriculum",
    rive: RiveModel(
      src: "assets/RiveAssets/icons.riv",
      artboard: "LIKE/STAR",
      stateMachineName: "STAR_Interactivity",
    ),
  ),
  Menu(
    title: "Mis Datos Personales",
    rive: RiveModel(
      src: "assets/RiveAssets/icons.riv",
      artboard: "CHAT",
      stateMachineName: "CHAT_Interactivity",
    ),
  ),
  Menu(
    title: "Cambiar Contraseña",
    rive: RiveModel(
      src: "assets/RiveAssets/icons.riv",
      artboard: "CHAT",
      stateMachineName: "CHAT_Interactivity",
    ),
  ),
  // Menu(
  //   title: "Cerrar Sesión",
  //   rive: RiveModel(
  //     src: "assets/RiveAssets/icons.riv",
  //     artboard: "CHAT",
  //     stateMachineName: "CHAT_Interactivity",
  //   ),
  // ),
];
List<Menu> sidebarMenus2 = [
  Menu(
    title: "Historia",
    rive: RiveModel(
      src: "assets/RiveAssets/icons.riv",
      artboard: "TIMER",
      stateMachineName: "TIMER_Interactivity",
    ),
  ),
  Menu(
    title: "Notificationes",
    rive: RiveModel(
      src: "assets/RiveAssets/icons.riv",
      artboard: "BELL",
      stateMachineName: "BELL_Interactivity",
    ),
  ),
];

List<Menu> bottomNavItems = [
  Menu(
    title: "Chat",
    rive: RiveModel(
      src: "assets/RiveAssets/icons.riv",
      artboard: "CHAT",
      stateMachineName: "CHAT_Interactivity",
    ),
  ),
  Menu(
    title: "Search",
    rive: RiveModel(
      src: "assets/RiveAssets/icons.riv",
      artboard: "SEARCH",
      stateMachineName: "SEARCH_Interactivity",
    ),
  ),
  Menu(
    title: "Timer",
    rive: RiveModel(
      src: "assets/RiveAssets/icons.riv",
      artboard: "TIMER",
      stateMachineName: "TIMER_Interactivity",
    ),
  ),
  Menu(
    title: "Notification",
    rive: RiveModel(
      src: "assets/RiveAssets/icons.riv",
      artboard: "BELL",
      stateMachineName: "BELL_Interactivity",
    ),
  ),
  Menu(
    title: "Profile",
    rive: RiveModel(
      src: "assets/RiveAssets/icons.riv",
      artboard: "USER",
      stateMachineName: "USER_Interactivity",
    ),
  ),
];
