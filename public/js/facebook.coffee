#window.fbAsyncInit = ->
#
#    FB.init
#        appId: "752382298105595"
#        status: true
#        cookie: true
#        xfbml: true
#
#    FB.Event.subscribe "auth.authResponseChange", (response) ->
#        if response.status is "connected"
#            testAPI()
#        else
#            FB.login()
#
#(() ->
#
#    script = $('<script></script>')
#        .attr
#            id: "facebook-jssdk"
#            async: true
#            src: "//connect.facebook.net/en_US/all.js"
#
#    $('script').eq(0).before(script)
#)()
#
#testAPI = ->
##    console.log "Welcome!    Fetching your information.... "
##    FB.api "/me", (response) ->
##        console.log "Good to see you, " + response.name + ".", response
##        $('body').append("<img src='http://graph.facebook.com/#{response.id}/picture?type=large'>")



getPhotoByEmail = (email, callback) ->

    getGooglePhoto = (gCallback) ->
        $.ajax
            url: "http://plus.google.com/complete/search"
            dataType: "jsonp"
            timeout: 5000
            data:
                client: "es-people-picker"
                q: email
            success: (googleData) ->
                if googleData?[1]?[0]?[3]?.b
                    gCallback(googleData[1][0][3].b)
                else
                    gCallback("")
            error: ->
                gCallback("")

    $.ajax
        url: "http://gravatar.com/#{md5 email}.json"
        dataType: "jsonp"
        timeout: 5000
        success: (data) ->

            if data?.entry?[0]
                gravatarProfile = data.entry[0]
                gravatarPhoto = gravatarProfile.photos?[0]?.value
                if gravatarPhoto
                    gravatarPhoto = gravatarPhoto += "?s=200"

                if gravatarProfile.accounts?.length
                    facebook = _.find gravatarProfile.accounts, (account) =>
                        account.domain is "facebook.com"


                    if facebook.url
                        if /profile\.php/.test(facebook.url)
                            facebookId = facebook.url.split("profile.php?id=")[1]
                        else
                            facebookUsername = facebook.url.split(".com/")[1]
                        facebookPhoto = "http://graph.facebook.com/#{facebookId or facebookUsername}/picture?type=large"

                        callback(facebookPhoto)

                    else
                        callback(gravatarPhoto)
            else
                getGooglePhoto(callback)

        error: ->
            getGooglePhoto(callback)
