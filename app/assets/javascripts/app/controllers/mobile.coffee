class Mobile
  constructor: ->
    # TODO: Remove this error notification when the mobile frontend switch is not needed any more.
    if not App.Config.get('mobile_frontend_enabled')
      @notify
        type:    'error'
        msg:     App.i18n.translateContent(__('Mobile frontend is disabled.'))
        timeout: 6000

      return

    @clearForceDesktopApp()

    if window.history?
      window.history.replaceState(null, null, '/mobile')

    window.location.href = '/mobile'

  clearForceDesktopApp: ->
    if App.LocalStorage.get('forceDesktopApp', false)
      App.LocalStorage.delete('forceDesktopApp')

App.Config.set('mobile', Mobile, 'Routes')

if isMobile()
  # TODO: Remove `mobile_frontend_enabled` check when this switch is not needed any more.
  App.Config.set('Mobile', { prio: 1500, parent: '#current_user', name: __('Continue to mobile'), translate: true, target: '#mobile', setting: ['mobile_frontend_enabled'] }, 'NavBarRight')
