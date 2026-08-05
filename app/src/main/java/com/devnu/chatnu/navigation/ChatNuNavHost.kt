package com.devnu.chatnu.navigation

import androidx.compose.animation.EnterTransition
import androidx.compose.animation.ExitTransition
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideOutHorizontally
import androidx.compose.runtime.Composable
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import com.devnu.chatnu.di.AppContainer
import com.devnu.chatnu.di.ConversationViewModelFactory
import com.devnu.chatnu.di.HomeViewModelFactory
import com.devnu.chatnu.di.NodeViewModelFactory
import com.devnu.chatnu.di.OnboardingViewModelFactory
import com.devnu.chatnu.di.SettingsViewModelFactory
import com.devnu.chatnu.feature.chat.ConversationScreen
import com.devnu.chatnu.feature.chat.ConversationViewModel
import com.devnu.chatnu.feature.home.HomeScreen
import com.devnu.chatnu.feature.home.HomeViewModel
import com.devnu.chatnu.feature.node.NodeScreen
import com.devnu.chatnu.feature.node.NodeViewModel
import com.devnu.chatnu.feature.onboarding.OnboardingScreen
import com.devnu.chatnu.feature.onboarding.OnboardingViewModel
import com.devnu.chatnu.feature.settings.SettingsScreen
import com.devnu.chatnu.feature.settings.SettingsViewModel

private object Routes {
    const val Onboarding = "onboarding"
    const val Home = "home"
    const val Nodes = "nodes"
    const val Settings = "settings"
    const val Chat = "chat/{conversationId}"
    fun chat(id: String) = "chat/$id"
}

@Composable
fun ChatNuNavHost(container: AppContainer) {
    val navController = rememberNavController()
    NavHost(
        navController = navController,
        startDestination = Routes.Onboarding,
        enterTransition = { fadeIn() },
        exitTransition = { fadeOut() },
        popEnterTransition = { fadeIn() },
        popExitTransition = { fadeOut() },
    ) {
        composable(Routes.Onboarding) {
            val vm: OnboardingViewModel = viewModel(factory = OnboardingViewModelFactory(container.identityStore))
            OnboardingScreen(vm, onContinue = {
                navController.navigate(Routes.Home) { popUpTo(Routes.Onboarding) { inclusive = true } }
            })
        }
        composable(Routes.Home) {
            val vm: HomeViewModel = viewModel(factory = HomeViewModelFactory(container.chatRepository))
            HomeScreen(
                viewModel = vm,
                onOpenConversation = { navController.navigate(Routes.chat(it)) },
                onOpenNodes = { navController.navigate(Routes.Nodes) },
                onOpenSettings = { navController.navigate(Routes.Settings) },
            )
        }
        composable(
            route = Routes.Chat,
            arguments = listOf(navArgument("conversationId") { type = NavType.StringType }),
            enterTransition = { slideInHorizontally(initialOffsetX = { it / 3 }) + fadeIn() },
            exitTransition = { ExitTransition.None },
            popEnterTransition = { EnterTransition.None },
            popExitTransition = { slideOutHorizontally(targetOffsetX = { it / 3 }) + fadeOut() },
        ) { entry ->
            val id = entry.arguments?.getString("conversationId").orEmpty()
            val vm: ConversationViewModel = viewModel(
                key = "conversation-$id",
                factory = ConversationViewModelFactory(container.chatRepository, id),
            )
            ConversationScreen(vm, onBack = navController::popBackStack)
        }
        composable(Routes.Nodes) {
            val vm: NodeViewModel = viewModel(factory = NodeViewModelFactory(container.chatRepository))
            NodeScreen(vm, onBack = navController::popBackStack)
        }
        composable(Routes.Settings) {
            val vm: SettingsViewModel = viewModel(factory = SettingsViewModelFactory(container.identityStore, container.chatRepository))
            SettingsScreen(vm, onBack = navController::popBackStack)
        }
    }
}
