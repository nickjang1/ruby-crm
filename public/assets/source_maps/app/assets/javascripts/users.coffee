$(document).ready ->
  $profileForm = $("form.user-profile")
  profileFormError = false
  confirmedUserName = null
  newUserForm = $profileForm.find("#profile").data("new")

  $profileForm.submit ->
    val = $("input[type=submit][clicked=true]").val()
    $("<input type='hidden' value='#{val}' name='submit_button'>").appendTo(@)

  validateEmailOrUsername = ->
    $email = $("#user_email")
    $username = $("#user_username")
    window.ParsleyUI.removeError($email.parsley(), "login")
    window.ParsleyUI.removeError($username.parsley(), "login") unless profileFormError
    window.ParsleyUI.removeError($username.parsley(), "username") unless profileFormError
    if !$email.val() && !$username.val()
      window.ParsleyUI.addError($email.parsley(), "login", " ")
      window.ParsleyUI.addError($username.parsley(), "login", "Please enter either an email or a username.")
      return false

    userName = $username.val()
    if !!userName && /^[a-zA-Z0-9_\.]*$/.test(userName)

    else
      if !!userName
        window.ParsleyUI.addError($username.parsley(), "username", "Username field does not accept special characters.")
        return false
      else
        $(".password-section").slideUp()
        $(".password-field").attr("disabled", true)
    true

  $profileForm.find("input[type=submit]").click ->
    $("input[type=submit]", $(this).parents("form")).removeAttr "clicked"
    $(this).attr "clicked", "true"
    return false if !validateEmailOrUsername() || profileFormError

  $profileForm.find(".select-avatar").on 'click', ->
    $profileForm.find("#avatar-file-field").trigger('click')
    $profileForm.find("#user_remove_avatar").attr "checked", false

  $profileForm.find("#avatar-file-field").on 'change', (e) ->
    evt = e.target
    if evt.files and evt.files[0]
      reader = new FileReader()
      reader.onload = (e) ->
        $profileForm.find("#avatar-img").attr "src", e.target.result
        return
      reader.readAsDataURL evt.files[0]
    submits = $profileForm.find('input.enabled-on-changes, button.enabled-on-changes')
    submits.prop('disabled', false)

  $profileForm.find(".remove-avatar").on 'click', ->
    $profileForm.find("#user_remove_avatar").attr "checked", true
    $profileForm.find("#avatar-img").attr "src", "/assets/adminre_theme_v120/image/avatar/avatar.png"
    $profileForm.find("#avatar-file-field").trigger('change')

  hideConfirmPanel = ->
    profileFormError = false
    window.ParsleyUI.removeError($(".username-field").parsley(), "login")
    $(".code-confirm").slideUp()

  $profileForm.find(".username-field").on "blur", (e) ->
    $this = $(@)
    userName = $this.val()
    profileFormError = false
    hideConfirmPanel()
    $(".password-section").slideUp()
    $(".password-field").attr("disabled", true)

    if validateEmailOrUsername() && !!userName
      if confirmedUserName != userName
        $("#code-confirmed-msg").hide()
        $.ajax(Routes.valid_username_users_path(),
          dataType: "JSON"
          method: "POST"
          data:
            username: userName
        ).done (data) ->
          if data.status == "not_valid"
            window.ParsleyUI.addError($this.parsley(), "login", "Username has been assigned to #{data.name}. Please choose unique username.")
            profileFormError = true
          else if data.status == "confirm_code"
            if newUserForm
              $("#username-code").val("").focus()
              $(".code-confirm").slideDown()
              window.ParsleyUI.addError($this.parsley(), "login", " ")
            else
              window.ParsleyUI.addError($this.parsley(), "login", "Username has been assigned. Please choose unique username.")
            profileFormError = true
          else
            $(".password-section").slideDown()
            $(".password-field").removeAttr("disabled")

  $("#cancel-confirm").on "click", (e) ->
    hideConfirmPanel()
    $(".username-field").val("").focus()
    validateEmailOrUsername()
    return false

  $("#username-code").on "keyup", (e) ->
    val = $(@).val().replace("_", "")
    disabled = val.length != 5
    $("#confirm-code").attr("disabled", disabled)

  $("#confirm-code").on "click", (e) ->
    $userName = $(".username-field")
    userName = $userName.val()
    $code = $("#username-code")
    $.ajax(Routes.confirm_username_users_path(),
      dataType: "JSON"
      method: "POST"
      data:
        username: userName
        code: $code.val()
    ).done (valid) ->
      if valid
        hideConfirmPanel()
        $("#code-confirmed-msg").show()
        confirmedUserName = userName
      else
        userNameConfirmed = null
        $("#username-code").val("").focus()
        profileFormError = true
        $(".code-confirm").slideDown()
        window.ParsleyUI.addError($code.parsley(), "login", " ")
    return false
