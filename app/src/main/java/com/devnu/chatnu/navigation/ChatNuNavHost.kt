package com.devnu.chatnu.navigation

import androidx.compose.animation.EnterTransition
import androidx.compose.animation.ExitTransition
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideOutHorizontally
import androidx.compose.runtime.Composable
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import com.devnu.chatnu.data.DemoChatRepository
import com.devnu.chatnu.feature.chat.ConversationScreen
import com.devnu.chatnu.feature.home.HomeScreen
import com.devnu.chatnu.feature.node.NodeScreen
import com.devnu.chatnu.feature.onboarding.OnboardingScreen
import com.devnu.chatnu.feature.settings.SettingsScreen

private object Routes {
    const val Onboarding = "onboarding"
    const val Home = "home"
    const val Nodes = "nodes"
    const val Settings = "settings"
    const val Chat = "chat/{conversationId}"
    fun chat(id: String) = "chat/$id"
}

@Composable
fun ChatNuNavHost(repository: DemoChatRepository) {
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
            OnboardingScreen(onContinue = {
                navController.navigate(Routes.Home) { popUpTo(Routes.Onboarding) { inclusive = true } }
            })
        }
        composable(Routes.Home) {
            HomeScreen(
                repository = repository,
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
            ConversationScreen(repository, id, onBack = navController::popBackStack)
        }
        composable(Routes.Nodes) { NodeScreen(repository, onBack = navController::popBackStack) }
        composable(Routes.Settings) { SettingsScreen(onBack = navController::popBackStack) }
    }
}
