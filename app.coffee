People = new Meteor.Collection "people"

People.allow
    insert: ->
        true
    update: ->
        true


Meteor.users.allow
    remove: ->
        true


App =

    selectors:
        person: ".people__person"
        searchInput: ".people__search-input"
        loveButton: ".people__love-button"
        unloveButton: ".people__unlove-button"
        saveButton: ".account__save"
        firstNameInput: ".account__first-name-input"
        lastNameInput: ".account__last-name-input"
        photoInput: ".account__photo-input"
        facebookInput: ".account__facebook-input"
        accountModal: "#account"

    MAX_LOVED_COUNT: 5

    nameSearchQuery: ""
    peopleListUpdateCounter: 0

    initialize: (collection) ->
        console.log "Initialized app", collection
        @collection = collection
        @initializeTemplates()
        @attachEvents()

    attachEvents: ->
        peopleEvents = {}
        peopleEvents["click #{@selectors.loveButton}"] = $.proxy @onLoveButtonClick, @
        peopleEvents["click #{@selectors.unloveButton}"] = $.proxy @onUnloveButtonClick, @
        peopleEvents["keyup #{@selectors.searchInput}"] = $.proxy @onSearchInputKeyup, @

        headerEvents = {}
        headerEvents["click #{@selectors.saveButton}"] = $.proxy @onSaveButtonClick, @

        Template.people.events peopleEvents
        Template.header.events headerEvents

    initializeTemplates: ->
        Template.header.currentPerson = $.proxy @getTemplateCurrentPerson, @
        Template.peopleList.lastUpdate = $.proxy @getTemplateLastUpdate, @
        Template.peopleList.peopleList = $.proxy @getTemplatePeopleList, @
        Template.notifications.notifications = $.proxy @getTemplateNotifications, @
        Template.notifications.currentPerson = $.proxy @getTemplateCurrentPerson, @

    getPerson: (userId) ->
        @collection.findOne userId: userId

    getCurrentPerson: ->
        @getPerson Meteor.userId()

    getPeopleWhoLovePerson: (username) ->
        currentPerson = @collection.findOne username: username
        people = []
        @collection.find().forEach (person) ->
            if currentPerson.username isnt person.username
                if currentPerson.username in person.loved
                    people.push(person)
        people

    getUsernameByEventObject: (e) ->
        $(e.currentTarget)
            .parents(@selectors.person)
            .data("username")

    getLovedByCount: (username) ->
        @getPeopleWhoLovePerson(username).length #TODO: add +1 later

    getTemplateLastUpdate: ->
        Session.get "lastUpdate"

    getTemplatePeopleSearch: ->
        query: @nameSearchQuery

    getTemplatePeopleList: ->

        currentPerson = @getCurrentPerson()
        currentPersonTemplateData = null
        people = []

        if @nameSearchQuery
            searchQueryWords = @nameSearchQuery.split(/\s+/)

        @collection.find({}, sort: firstName: 1).forEach (person) =>

            templateData = {}
            if currentPerson

                templateData =
                    isLoved: person.username in currentPerson.loved
                    loggedIn: true
                    lovedBy: @getLovedByCount person.username

                if currentPerson.userId is person.userId
                    templateData.isCurrentUser = true
                    currentPersonTemplateData = _.extend(templateData, person)
                else
                    people.push _.extend(templateData, person)

            else
                templateData =
                    loggedIn: false
                    lovedBy: @getLovedByCount person.username
                people.push _.extend(templateData, person)

        if @nameSearchQuery
            people = people.filter (person) =>
                name = person.firstName + " " + person.lastName
                _.find name.split(/\s+/), (nameWord) =>
                    _.find searchQueryWords, (searchQueryWord) =>
                        nameWord.toLowerCase().indexOf(searchQueryWord.toLowerCase()) is 0

        people.unshift currentPersonTemplateData
        people

    getTemplateCurrentPerson: ->
        currentPerson = @getCurrentPerson()
        if currentPerson
            lovedBy = @getLovedByCount currentPerson.username
            _.extend lovedBy: lovedBy, currentPerson

    getTemplateNotifications: ->
        currentPerson = @getCurrentPerson()
        if currentPerson
            if currentPerson.username.toLowerCase() in ["egorvinogradov.ru", "elizabeth76"] # TODO: remove
                peopleWhoLoveCurrentPerson = @getPeopleWhoLovePerson currentPerson.username
                peopleIdsWhoLoveCurrentPerson = _.pluck(peopleWhoLoveCurrentPerson, "username")
                intersectionIds = _.intersection peopleIdsWhoLoveCurrentPerson, currentPerson.loved
                _.map intersectionIds, (username) =>
                    @collection.findOne username: username

    onLoveButtonClick: (e) ->

        currentPerson = @getCurrentPerson()
        username = @getUsernameByEventObject(e)

        if username isnt currentPerson.username
            loved = currentPerson.loved
            unless loved.length >= @MAX_LOVED_COUNT
                loved.push(username)
                query = _id: currentPerson._id
                @collection.update query, $set:
                    loved: loved
                console.log("Loved", username)

    onUnloveButtonClick: (e) ->
        currentPerson = @getCurrentPerson()
        username = @getUsernameByEventObject(e)
        if username isnt currentPerson.username
            loved = currentPerson.loved
            loved = _.without(loved, username)
            query = _id: currentPerson._id
            @collection.update query, $set:
                loved: loved
            console.log("Unloved", username)

    onSaveButtonClick: (e) ->
        e.preventDefault()
        e.stopPropagation()
        values =
            firstName: $.trim $(@selectors.firstNameInput).val()
            lastName: $.trim $(@selectors.lastNameInput).val()
            photo: $.trim $(@selectors.photoInput).val()
            facebook: $.trim $(@selectors.facebookInput).val()
        query = _id: @getCurrentPerson()._id
        $(@selectors.accountModal).modal "hide"

        setTimeout =>
            @collection.update query, $set: values
        , 500

    onSearchInputKeyup: (e) ->
        @nameSearchQuery = $.trim $(e.currentTarget).val()
        Session.set "lastUpdate", new Date()

#    __generatePeople: ->
#        _UserList.forEach (user) ->
#            People.insert
#                firstName: user[1]
#                lastName: user[0]
#                email: user[2]
#                username: user[2].split("@")[0]
#                about: ""
#                loved: []
#                photo: ""
#                userId: ""
#                facebook: ""
#                activated: false



if Meteor.isClient
    App.initialize(People)



if Meteor.isServer
    Accounts.onCreateUser (options, user) ->
        currentPerson = People.findOne(email: options.email)
        if currentPerson
            console.log("Activated user", options.email, user._id, currentPerson.name)
            query = _id: currentPerson._id
            People.update query, $set:
                activated: true
                userId: user._id
        else
            console.log("Can't find user with email", options.email)
            user.emails[0].address = "Invalid email"
        user




`__People = People` # TODO: remove after debug
`__App = App` # TODO: remove after debug




#_UserList = [
#    ["Ahn", "Seyeon", "tpdus4522@naver.com"]
#    ["Alakeel", "Rakan Ibrahim A", "reko0o-12@hotmail.com"]
#    ["Alammari", "Hassan Mohammed R", "hassony451@hotmail.com"]
#    ["Alanazi", "Arwa Khalid S", "arwakhaled@hotmail.com"]
#    ["Albiñana Martinez", "Ignacio", "Ignacioam@vitroval.com"]
#    ["Aldhahri", "Abeer Talal O", "x-mp3@hotmail.com"]
#    ["Aldossari", "Theeb Fahad M", "theeb34@hotmail.com"]
#    ["Alghslan", "Waheed Saleh F", "my9669@hotmail.com"]
#    ["Alharbi", "Amer Essam A", "amer_352_mb2@hotmail.com"]
#    ["Alhathal", "Hussam Fahad K", "hussam.alhthal@gmail.com"]
#    ["Alkhaldi", "Mashare Talal A", "mashare1@hotmail.com"]
#    ["Alluqmani", "Mohammed Kamel S", "xx_xx_010@hotmail.com"]
#    ["Almuzayil", "Abdulrahman Ahmed A", "dhome-98@hotmail.com"]
#    ["Alosaimi", "Naif Mohammed F", "naif.osaimi90@hotmail.com"]
#    ["Alotaibi", "Ahmed Bijad M", "ahmadalotaibi25@gmail.com"]
#    ["Alqurashi", "Matooq Mohammed A", "mmaalqurashi@gmail.com"]
#    ["Alrefae", "Fahad Khalid A", "Fahad.5005@hotmail.com"]
#    ["Alshahrani", "Abdulmajeed Saeed A", "musader11@hotmail.com"]
#    ["Alsharif", "Rashed Mahdi M", "rashid.m.alsharif@gmail.com"]
#    ["Alsowayigh", "Fawaz Abdullah I", "fbi.3@hotmail.com"]
#    ["Alyazidi", "Bandar Mohammed S", "Ban076@hotmail.com"]
#    ["Alzahrani", "Mutab Abdulmajeed A", "m-alzhrani07@gmail.com"]
#    ["Aragao de Oliveira", "Rita de Cassia", "ritac.aragao@gmail.com"]
#    ["Babakr", "Majed Omar S", "foryou758@hotmail.com"]
#    ["Back", "Seung-Kwan", "silenearmeria@hotmail.com"]
#    ["Bahattab", "Afnan Mohammed S", "bsher-100@hotmail.com"]
#    ["Bakhadlaq", "Athare Eid S", "angel.aa.b@hotmail.com"]
#    ["Bantan", "Kamal Azdi R", "Kamalazdi@hotmail.com"]
#    ["Bin Shareef", "Lamia", "al-shareef@msn.com"]
#    ["Brandão Pelho", "Fabio", "fabiopelho@yahoo.com.br"]
#    ["Caliskan", "Recep", "recep_clskn@hotmail.com"]
#    ["Campos Morgado", "Diogo", "diogocmorgado@gmail.com"]
#    ["Carena", "Matthieu Denis", "Matthieucarena@hotmail.fr"]
#    ["Carrera Betancourt", "Claudio Armando", "carrera.claudio@hotmail.com"]
#    ["Chapagain", "Bikash", "me_bikashc@hotmail.com"]
#    ["Chen", "Liu Jin", "545505714@qq.com"]
#    ["Chen", "Hong", "calhchen@hotmail.com"]
#    ["Choi", "Younggon", "choi5314@hanmail.net"]
#    ["Choi", "Seungpil", "choisp91@gmail.com"]
#    ["Chou", "Shu-Yi", "lineage2250@gmail.com"]
#    ["da Silva Holanda Freitas Benevides", "Viviane", "vivianesilvaadm@hotmail.com"]
#    ["Dahlawi", "Eman Hassan I", "eman.dahlawi@gmail.com"]
#    ["Das Chagas Alves Pereira De Souza", "Gabriel", "Gabriel.chagas19@gmail.com"]
#    ["De Sousa Felipe", "Luciana Flavia", "Lucianafsfelipe@gmail.com"]
#    ["Denny", "Andressa Carolina", "Andressacdenny@hotmail.com"]
#    ["Dognani Prestes", "Felipe", "felipe_prestes@hotmail.com"]
#    ["Dubois", "Michael", "michael.dubois34790@gmail.com"]
#    ["Ducry", "Barbara", "barbara_ducry@hotmail.com"]
#    ["Erkan", "Mehmet Kaan", "mehmetkaan_32@hotmail.com"]
#    ["Falcone", "Selina", "selinafalcone@gmail.com"]
#    ["Freire", "Luiz Carlos Nishikido Americano", "Lcnafreire1@outlook.com"]
#    ["Gonzalez de Leon", "Giuliana", "giuli_95_g@hotmail.com"]
#    ["Gutierrez Vega", "Maria Paula", "mapagutive@hotmail.com"]
#    ["Herrera Sommerkamp", "Janina", "janina_herrera@hotmail.com"]
#    ["Hobani", "Menaji Ibrahim A", "fnoonjazan@yahoo.com"]
#    ["Hsieh", "Chen-Yu", "jimmyxts@gmail.com"]
#    ["Huang", "Zi Yu", "ziyuhuang94@163.com"]
#    ["Huang", "Chien-Chung", "eric85085@yahoo.com.tw"]
#    ["Huang", "Han Mo", "Huanghanmonick@gmail.com"]
#    ["Ilyukin", "Gennady", "gennady.ilyukin@gmail.com"]
#    ["Jang", "Soobin", "j1001sb@nate.com"]
#    ["Jaun", "Woongsik", "jws5704@naver.com"]
#    ["Jauss", "Luana Sarah", "luana.jauss@gmail.com"]
#    ["Jin", "Gu Xin", "jgxking@hotmail.com"]
#    ["Joshi", "Chiran", "chiranjoshi@gmail.com"]
#    ["Jung", "Donghwan", "Mcsouist@gmail.com"]
#    ["Kalay", "Oguzhan", "oguzhan_kalay@hotmail.com"]
#    ["Kang", "Kiwon", "darkrja@gmail.com"]
#    ["Kato", "Eri", "ronchan0415@gmail.com"]
#    ["Khorshied", "Asmaa Roshdy Moustafa", "asmaashrek@yahoo.com"]
#    ["Kim", "Jisun", "elizabeth76@naver.com"]
#    ["Kim", "Ah Young", "lungpuha@naver.com"]
#    ["Kim", "Jeewook", "jwhero94@gmail.com"]
#    ["Kim", "Hyungjun", "kim000128@naver.com"]
#    ["Kim", "Hojin", "gganja8568@nate.com"]
#    ["Kim", "Bo Min", "biggemkim@naver.com"]
#    ["Küng", "Mario André", "mario_kueng@hotmail.com"]
#    ["Kurdi", "Azhar Ibrahim A", "azhar.kurdi@gmail.com"]
#    ["Lee", "Chihoon", "ch4930@naver.com"]
#    ["Lee", "Yu Jin", "yugirl7@naver.com"]
#    ["Lee", "Min Jung", "minjung22@hotmail.com"]
#    ["Lee", "Seokjin", "TonyJin0801@gmail.com"]
#    ["Li", "Lu", "lucy.lilu100@gmail.com"]
#    ["Lin", "Yang-Chiao", "supergoodjamie1995@gmail.com"]
#    ["Liu", "Yi-Shan", "birdie613@yahoo.com.tw"]
#    ["Liu", "Kai Lun", "mangguo1990@sina.cn"]
#    ["Luo", "Jin Hong", "jieloh@foxmail.com"]
#    ["Ma", "Ke Xuan", "kema145@hotmail.com"]
#    ["Machado Lima Junior", "Ruy", "docruy2@hotmail.com"]
#    ["Manaf", "Qosi Abdulrahman A", "qusai-7@hotmail.com"]
#    ["Mao", "Qin Yu", "maoqinyu226@gmail.com"]
#    ["Maqbool", "Yaser Hasan A", "Ysr85@hotmail.com"]
#    ["Marquez Barrios", "Fabiola", "fabiolamarquezb@yahoo.es"]
#    ["Marubayashi", "Rodrigo Tsutomo", "rtmaruba@hotmail.com"]
#    ["Moon", "Ju Youn", "newco92@gmail.com"]
#    ["Morimoto", "Moe", "moe0327.g@gmail.com"]
#    ["Mukhamejanov", "Zhomart", "mzhomart@gmail.com"]
#    ["Najjar", "Mariam M H", "getemail@school.com"]
#    ["Naruse", "Natsumi", "sora-haru.723@ezweb.ne.jp"]
#    ["Ninomiya", "Mahiro", "locoxgirl625@gmail.com"]
#    ["Numbi", "Nancy Ngoi", "n.tatiana@gmail.com"]
#    ["Oda", "Yutaka", "utkoda@yahooo.co.jp"]
#    ["Oliveira Jalbut", "Cynthia", "cyjalbut@hotmail.com"]
#    ["Ondar", "Artysh", "a.v.ondar@mail.ru"]
#    ["Park", "Taeyoung", "1230tyty@naver.com"]
#    ["Park", "Jiyoung", "jyp603@naver.com"]
#    ["Polcaro", "Daniel Ribeiro", "polcaro.daniel@gmail.com"]
#    ["Polizzi", "Giuliana", "giuli.pol@gmail.com"]
#    ["Quiñonez Gomez", "Carla", "carlaq@gmail.com"]
#    ["Rissato", "Aron Henrique", "Aron_rissato@hotmail.com"]
#    ["Rodrigues", "Luana Cristina", "luanamussnich@gmail.com"]
#    ["Salbieva", "Svetlana", "lana.salbieva@mail.ru"]
#    ["Sauge", "Benjamin", "benjaminsauge@hotmail.fr"]
#    ["Schneider", "Gabriel", "gabrielschneider92@hotmail.com"]
#    ["Seo", "Heegyeong", "gntzzz@daum.net"]
#    ["Shen", "Zhen Yao", "Wilsonshen2010@gmail.com"]
#    ["Shi", "Hao Ran", "499349771@qq.com"]
#    ["Shin", "SangHyeok", "Sin8541@naver.com"]
#    ["Shrestha", "Shruti", "shruti_shrestha4@hotmail.com"]
#    ["Sim", "Misun", "tiny0727@hanmail.net"]
#    ["Sugawara", "Hiroaki", "hiro_sugawara@hotmail.co.jp"]
#    ["Sun", "Hao Feng", "734356126@qq.com"]
#    ["Tagle Schmidt", "Elvira", "elviratagle@gmail.com"]
#    ["Tajirian", "Jean Wahan Yerchanik", "jean_tajirian@hotmail.com"]
#    ["Tak", "Seongho", "Sfbriant@gmail.com"]
#    ["Tang", "Jun", "492123374@qq.com"]
#    ["Tanrikulu", "Selin", "selint91@gmail.com"]
#    ["Thapa", "Amit", "thapaamit2002@icloud.com"]
#    ["Uettwiller", "Lea", "lea.uettwiller@gmail.com"]
#    ["Valenga", "Henrique Meister", "Henriquemvalenga@gmail.com"]
#    ["Viboonlarp", "Sirasit 'Mikey'", "draker-never-more@hotmail.com"]
#    ["Victor", "Rogerio Carlos", "rogeriovictor@hotmail.com"]
#    ["Vinogradov", "Egor", "egorvinogradov.ru@gmail.com"]
#    ["Wang", "Rui Lin 'Ricky'", "wang_ruilin@126.com"]
#    ["Weng", "Yuan Ran", "514406355@qq.com"]
#    ["Wu", "Jia Mian", "Rayrabbit34@gmail.com"]
#    ["Wu", "Jia Kun", "499352464@qq.com"]
#    ["Xie", "Yu Li", "417728565@qq.com"]
#    ["Yan", "Yu", "ryanyan0411@gmail.com"]
#    ["Yang", "Dong", "513821877@qq.com"]
#    ["Yang", "Young Bin", "stay901010@naver.com"]
#    ["Yang", "Hee Jin", "hopenlove.jinny@gmail.com"]
#    ["Yang", "Che-Chia", "chai80527@hotmail.com"]
#    ["Ye", "Guanghao", "841878242@qq.com"]
#    ["Yu", "Elizabeth", "smilebeth918@gmail.com"]
#    ["Yu", "SeungHee", "strawberry94@naver.com"]
#    ["Yuan", "Wu Feng", "13770714040@163.com"]
#    ["Yuksel", "Deniz", "refik.yuksel@dlh.de"]
#    ["Yuksel", "Irem", "irem.yksel@gmail.com"]
#    ["Zhang", "Bai Tao", "785164219@qq.com"]
#    ["Zheng", "Zi Yun", "13350016969@463.com"]
#    ["Zhou", "En Min", "381719684@qq.com"]
#    ["Zhuang", "Ming Xun", "657253726@qq.com"]
#    ["Passos", "Williane", "willianepassos@hotmail.com"]
#    ["Holsworth", "Lisa", "lisa5698@gmail.com"]
#    ["Skinner", "Scott", "skinner.scott78@gmail.com"]
#]
