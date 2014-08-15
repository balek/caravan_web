window.addEventListener 'load', ->
        FastClick.attach document.body
    , false

# document.ontouchmove = (e) ->
#     do e.preventDefault


# if document.location.protocol == "file:" or document.location.host == 'localhost:8080'
wsuri = "ws://cr/ws"
# else
#     wsuri = (if document.location.protocol == "http:" then "ws:" else "wss:") + "//" +
#                 document.location.host + "/ws"


class deviceController
    constructor: ($attrs, $scope, caravan) ->
        @name = $attrs.deviceName
        @caravan = caravan

        $scope.$on 'connected', =>
            @caravan.call "#{@name}.get"
                .then (value) =>
                    @state = value
                    $scope.$digest()

        @caravan.subscribe @name + '.changed', (args) =>
                @state = args[0]
                $scope.$digest()

    call: (command, args...) ->
        @caravan.call "#{@name}.#{command}", args


angular.module 'devicesApp', ['angular-blocks']
    .service 'caravan', ($rootScope) ->
        @subscriptions = []
        @connected = false

        @connection = new autobahn.Connection
            url: 'ws://cr/ws'
            realm: 'realm1'

        @connection.onopen = (@session, details) =>
            @connected = true
            for subscription in @subscriptions
                @session.subscribe subscription.name, subscription.func
            $rootScope.$broadcast 'connected'
            do $rootScope.$digest

        @subscribe = (name, func) =>
            @subscriptions.push
                name: name
                func: func
            if @connected
                @session.subscribe name, func
        @call = (command, args, kwargs) =>
            @session.call(command, args, kwargs)

        do @connection.open


    .controller 'deviceController', deviceController
    .run ($rootScope, caravan) -> $rootScope.caravan = caravan