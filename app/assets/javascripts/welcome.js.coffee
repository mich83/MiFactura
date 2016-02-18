# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/


onload = () ->
  button_click = (param) ->
    count = 0
    for btn in $("[id*=push_button]")
      if btn.id != "push_button_0"
        count++
    if typeof param == "string"
      id = param
    else
      id = param.currentTarget.id
    x = id.replace("push_button_","")
    if (x == "4")
      x = "3"
    if (x != "0")
      if $('#layer'+x)[0].style.display != "none"
        x = "0"
    for n in [1..count]
      $('#layer'+n).hide()
    if (x != "0")
      for n in [1..count]
        $('#push_button_'+n).hide()
      if $('#layer'+x).hasClass('hidden')
        $('#layer'+x).removeClass('hidden')
      if $(window).width() > 768
        $('#push_button_'+x).show()
      $('#layer'+x).show()
    else
      for n in [1..count]
        $('#push_button_'+n).show()
    false
  button_click("push_button_0")
  $("[id*=push_button]").bind('click',(event)->button_click(event))

$(window).bind("load", onload)
$(document).on("page:load", onload)
