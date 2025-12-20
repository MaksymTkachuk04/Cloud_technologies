output "created_user_login" {
  value = azuread_user.az104_user1.user_principal_name
  description = "Логін створеного юзера"
}

output "created_user_password" {
  value     = random_password.az104_user_pw.result
  sensitive = true
  description = "Пароль юзера"
}

output "group_name" {
  value = azuread_group.it_lab_admins.display_name
  description = "Назва створеної групи"
}

output "guest_invite_status" {
  value = "Invitation sent to ${azuread_invitation.guest_user.user_email_address}"
}

output "group_portal_url" {
  value = "https://portal.azure.com/#view/Microsoft_AAD_IAM/GroupDetailsMenuBlade/~/Overview/groupId/${azuread_group.it_lab_admins.object_id}"
  description = "Посилання на групу в порталі"
}