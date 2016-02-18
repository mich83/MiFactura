#$ ->
#  notice = ""
#  for elem in $("#dialog p")
#    notice = notice+elem.innerHTML
#  if notice? && notice.length>0
#    $("#dialog").dialog
#      buttons:
#        "OK": ->
#          $(this).dialog("close")
#  true
#  $(":file").filestyle
#    buttonName: "btn-primary"
#    icon: false
#    buttonText: "Elige el archivo"

#$(window).bind("load", search_notice)
#search_notice()

$ ->
  $(".alert").alert()
