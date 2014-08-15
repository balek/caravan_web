# if document.location.origin == "file://"
#     wsuri = "ws://127.0.0.1:8080/ws"
# else
#     wsuri = (if document.location.protocol == "http:" then "ws:" else "wss:") + "//" +
#                 document.location.host + "/ws";
#
# modules = []
#
# connection = new autobahn.Connection
#     url: wsuri
#     realm: "realm1"
#
# connection.onopen = (session, details) ->
#     window.ses = session;
#     console.log "Connected"
#
#     session.subscribe 'announce', (args) ->
#         modules.push args[0]
#         angular.element(document.body).scope().$digest()
#
#     session.publish 'discover'
#
#
# do connection.open

angular.module 'vanDiscoveryApp', []
    .controller 'deviceController', ($scope) ->
        if $scope.path
            $scope.path += '.' + $scope.device.name
        else
            $scope.path = $scope.device.name
        $scope.children = []
        $scope.showChildren = ->
            if $scope.children.length
                $scope.children = []
                return

            ses.call $scope.path + '.list'
                .then (res) ->
                    $scope.children = res
                    $scope.$digest()

        $scope.args = []
        if 'list' of $scope.device.commands
            $scope.device.hasChildren = true
            delete $scope.device.commands['list']
        delete $scope.device.commands['get']

        commands = Object.keys $scope.device.commands

        $scope.device.hasCommands = commands.length
        if commands.length
            $scope.device.currentCommand = commands[0]
        $scope.call = ->
            argTypes = $scope.device.commands[$scope.device.currentCommand]
            ses.call "#{$scope.path}.#{$scope.device.currentCommand}", $scope.args[..argTypes.length]

        ses.subscribe $scope.path + '.changed', (state) ->
                $scope.device.state = state[0]
                do $scope.$digest
            .then (subscription) ->
                $scope.$on '$destroy', -> do subscription.unsubscribe
    .run ($rootScope) ->
        $rootScope.modules = modules
