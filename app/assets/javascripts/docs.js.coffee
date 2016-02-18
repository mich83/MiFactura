# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/


$ ->
  onModalShown = () ->
    clavebox = $('#clavebox')[0]
    clavebox.value = $('#doc_clave')[0].innerHTML
    clavebox.focus()
    clavebox.select()

  onKeyPress = (btn) ->
    if btn.key == "Enter"
      $('#clave').modal('toggle')

  $('#clave').on('shown.bs.modal', onModalShown)
  $('#clavebox').keypress(onKeyPress)
