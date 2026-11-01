# Local shell controls for the existing Mihomo system service.
function clash() {
  case "${1:-help}" in
    on)
      export http_proxy=http://127.0.0.1:7890 https_proxy=http://127.0.0.1:7890
      export HTTP_PROXY=http://127.0.0.1:7890 HTTPS_PROXY=http://127.0.0.1:7890
      export all_proxy=socks5h://127.0.0.1:7890 ALL_PROXY=socks5h://127.0.0.1:7890
      export no_proxy=localhost,127.0.0.1,::1 NO_PROXY=localhost,127.0.0.1,::1
      print 'Proxy enabled for this shell: 127.0.0.1:7890'
      ;;
    off)
      unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY all_proxy ALL_PROXY no_proxy NO_PROXY
      print 'Proxy disabled for this shell'
      ;;
    status)
      systemctl --user --no-pager status clash-verge.service
      print "Shell HTTP proxy: ${http_proxy:-off}"
      ;;
    start|stop|restart|reload)
      if [[ "$1" == reload ]]; then
        systemctl --user restart clash-verge.service
      else
        systemctl --user "$1" clash-verge.service
      fi
      ;;
    update)
      print 'Use the refresh button on the subscription card in Clash Verge Rev.'
      clash ui
      ;;
    subscription)
      print 'Edit the subscription in Clash Verge Rev > Subscriptions.'
      clash ui
      ;;
    config)
      print 'Manage profile configuration in Clash Verge Rev > Subscriptions.'
      clash ui
      ;;
    ui)
      systemctl --user start clash-verge.service || return
      ( sleep 1; command clash-verge >/dev/null 2>&1 ) &!
      ;;
    help|-h|--help)
      print -r -- 'clash on/off        Enable/disable proxy for this shell
clash status        Show service and shell status
clash start/stop/restart/reload
                    Control the Clash Verge desktop client
clash ui            Open Clash Verge Rev
clash subscription  Open subscription management
clash update        Open client for manual subscription update
clash config        Open profile management'
      ;;
    *) print -u2 'Unknown command. Run: clash help'; return 2 ;;
  esac
}
