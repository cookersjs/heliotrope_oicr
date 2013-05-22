# Directives 

angular
  .module('heliotrope.directives.navigation', [])

  # Used to generate a dropdown menu of the available workflows. These can then be
  # used to direct to a form on selection. 
  
  .directive('heliWorkflows', () ->
    result = 
      restrict: "A"
      replace: true
      transclude: true
      template: '<ul class="dropdown-menu">' +
                '<li ng-repeat="step in entity.data.availableSteps">' +
                '<a href="{{step.url}}">{{step.label}}</a>' +
                '</li>' +
                '</ul>'
  )

  .directive('heliKnowledgeBaseSearch', ($http) ->
    result = 
      restrict: "A"
      scope: { term: '&', entity: '&entity' }
      link: (scope, iElement, iAttrs, controller) ->
        scope.$watch "term", (newTerm) ->
          term = newTerm()
          if term
            scope.$watch "entity", (newEntity) ->
              entity = newEntity()
              if entity

                serviceUrl = entity.data.config.knowledgeServiceUrl + "/variants/" + term
                frontUrl = entity.data.config.knowledgeUrl + "/variants/" + term

                $http(
                  method: 'GET'
                  url: serviceUrl
                ).success((data, status, headers, config) ->
                  jQuery(iElement).html("<a href='" + frontUrl + "'>" + frontUrl + "</a>")
                ).error((data, status, headers, config) ->
                  jQuery(iElement).html("<span class='warn'>Not found in knowledge base</span>")
                )
                  
  )

  .directive('heliSection', () ->
      priority: 1
      restrict: "A"
      replace: true
      transclude: true
      scope: { title: '@title', id: '@bodyId' }
      template: '<div class="row-fluid">' +
                '<div class="tab-content">' +
                '<div class="tab-pane active">' +
                '<div class="row-fluid">' + 
                '<h3 class="pull-left" id="{{id}}">{{title}}</h3>' +
                '</div>' +
                '<div class="body" ng-transclude></div>' +
                '</div' +
                '</div>'
      link: (scope, iElement, iAttrs, controller) ->
        navElement = jQuery("#sidebar .nav-list")
        id = iAttrs["bodyId"]
        title = iAttrs["title"]
        newElement = jQuery("<li><a class='nav-section' href='#" + id + "'>" + title + "</a></li>")
        newElement.appendTo(navElement)
        newElement.click (e) ->
          e.preventDefault()
          e.stopPropagation()
          target = e.currentTarget.firstChild.getAttribute('href')
          offset = jQuery(target).offset().top - 150
          jQuery("body").animate({scrollTop: offset}, 'slow')
          true
  )
  