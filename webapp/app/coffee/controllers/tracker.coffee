angular
  .module('heliotrope.controllers.tracker', [])

  .controller('StudyListController', ($scope, $routeParams, $timeout, StudyList) ->
    $scope.studies = StudyList.get($routeParams
      (study) ->

      (error) ->
        console.log error
    )
  )

  .controller('StudyController', ($scope, $routeParams, $timeout, Study) ->
    $scope.study = Study.get($routeParams
      (study) ->

      (error) ->
        console.log error
    )
  )

  .controller('EntityController', ($scope, $routeParams, $timeout, Entity) ->
    $scope.entity = Entity.get($routeParams
      (entity) ->

      (error) ->
        console.log error
    )
  )

  .controller('EntityStepController', ($scope, $routeParams, $timeout, $location, EntityStep) ->
    $scope.entity = EntityStep.get($routeParams
      (entityStep) ->
        
      (error) ->
        console.log error
    )
    
    # This is where the step data is pushed back to the service. 
    $scope.update = (entity) =>
      entity.$save(
        {study: $routeParams.study, role: $routeParams.role, identity: $routeParams.identity, step: $routeParams.step}, 
        (entityStep, responseHeaders) =>
          $location.path(entityStep.data.url).replace()
        (error) ->
          console.log "Error from $save", error
          $scope.error = error
      )
  )

  .controller('AdminController', ($scope, $routeParams, $timeout, StudyList) ->

    $scope.studiesAvailable = false

    $scope.studies = StudyList.get(
      {}
      () -> $scope.studiesAvailable = true
      () -> 
    )
  )

  # A relatively neutral controller that can create an initial empty study or 
  # retrieve an identified one. We can always well which by the presence/absence
  # of the _id. 

  .controller('AdminStudyController', ($scope, $routeParams, $location, Study) ->

    $scope.study = new Study()

    if ($routeParams["study"])
      $scope.study = Study.get($routeParams
        (study) ->

        (error) ->
          console.log error
      )
  
    $scope.update = () ->
      $scope.study.$save()
      $location.path("admin")

    $scope.newStep = (study) ->
      console.log "newStep", study
      $location.path("admin/steps/" + study.data.name)

    $scope.editStep = (study, step) ->
      console.log "editStep", study, step
      $location.path("admin/steps/" + study.data.name + "/" + step["appliesTo"] + "/" + step["name"])
  )

  # A relatively neutral controller that can create an initial empty study or 
  # retrieve an identified one. We can always well which by the presence/absence
  # of the _id. 

  .controller('AdminStepController', ($scope, $routeParams, $location, Step) ->

    $scope.original = new Step()

    $scope.fieldTypes = ["String", "Boolean", "Integer", "Reference", "Float", "File", "Date"]
    $scope.controlTypes = ["identity", "select", "date", "integer", "textarea", "file", "chooser", "checkbox", "float", "hidden", "text"]

    $scope.step = new Step()
    $scope.fields = []

    # We actually unpack fields into a separate array, because iterating over a 
    # hash is really bad form. We therefore need to repack on save. 
    initializeFields = () ->
      if $scope.step.data.step.fields
        fields = angular.copy($scope.step.data.step.fields)
        $scope.fields = Object.keys(fields).map (key) ->
          field = fields[key]
          field["key"] = key
          field

    if $routeParams["study"] && $routeParams["role"] && $routeParams["step"]
      $scope.step = Step.get($routeParams
        (step) ->
          angular.copy($scope.step, $scope.original)
          initializeFields()
        (error) ->

      )
  
    $scope.update = () ->

      fields = new Object
      $scope.fields.forEach (field) ->
        key = field["key"]
        delete field["key"]
        fields[key] = field

      $scope.step.data.step.fields = fields

      $scope.step.$save()
      $location.path("admin/studies/" + $scope.step.data.study.name + "/steps")

    $scope.resetStep = () ->
      angular.copy($scope.original, $scope.step)
      initializeFields()
  )

  # A relatively neutral controller that can create an initial empty study or 
  # retrieve an identified one. We can always well which by the presence/absence
  # of the _id. 

  .controller('AdminViewController', ($scope, $routeParams, $location, View) ->

    $scope.original = new View()

    $scope.view = new View()

    if $routeParams["study"] && $routeParams["role"] && $routeParams["view"]
      $scope.view = View.get($routeParams
        (view) ->
          angular.copy($scope.view, $scope.original)
        (error) ->
          console.log error
      )

    $scope.resetView = () ->
      angular.copy($scope.original, $scope.view)
  
    $scope.update = () ->
      $scope.view.$save()
      $location.path("admin/studies/" + $scope.view.data.study.name + "/views")
  )

  # A relatively neutral controller that can create an initial empty study or 
  # retrieve an identified one. We can always well which by the presence/absence
  # of the _id. 

  .controller('AdminViewsController', ($scope, $routeParams, $location, Views) ->

    $scope.views = Views.get($routeParams
      (study) ->

      (error) ->
        console.log error
    )
  
    $scope.newView= (study) ->
      console.log "newView", study
      console.log "admin/steps/" + $scope.views.data.study.name
      # $location.path("admin/steps/" + $scope.views.data.study.name)

    $scope.editView = (study, view) ->
      console.log "editView", study, view
      console.log "admin/views/" + $scope.views.data.study.name + "/" + view["role"] + "/" + view["name"]
      $location.path("admin/views/" + $scope.views.data.study.name + "/" + view["role"] + "/" + view["name"])

  )
