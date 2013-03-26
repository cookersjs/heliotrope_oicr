// Generated by CoffeeScript 1.3.3
(function() {

  angular.module('heliotrope', ['heliotrope.filters', 'heliotrope.services', 'heliotrope.directives', 'knowledge.services']).config([
    '$routeProvider', function($routeProvider) {
      $routeProvider.when("/", {
        templateUrl: 'app/partials/home.html',
        controller: "HomeController"
      });
      $routeProvider.when("/genes", {
        templateUrl: 'app/partials/home.html',
        controller: "HomeController"
      });
      $routeProvider.when("/genes/:gene", {
        templateUrl: 'app/partials/gene.html',
        controller: "GeneController"
      });
      $routeProvider.when("/variants/:variant", {
        templateUrl: 'app/partials/variant.html',
        controller: "VariantController"
      });
      $routeProvider.when("/studies/:study", {
        templateUrl: 'app/partials/study.html',
        controller: "StudyController"
      });
      $routeProvider.when("/studies/:study/:role/:identity", {
        templateUrl: 'app/partials/entity.html',
        controller: "EntityController"
      });
      $routeProvider.when("/studies/:study/:role/:identity/step/:step", {
        templateUrl: 'app/partials/step.html',
        controller: "EntityStepController"
      });
      return $routeProvider.otherwise({
        redirectTo: "/view1"
      });
    }
  ]).config([
    '$locationProvider', function($locationProvider) {
      $locationProvider.html5Mode(true);
      return $locationProvider.hashPrefix = "!";
    }
  ]);

  jQuery.extend(jQuery.fn.dataTableExt.oStdClasses, {
    "sSortAsc": "header headerSortDown",
    "sSortDesc": "header headerSortUp",
    "sSortable": "header"
  });

  jQuery.extend(jQuery.fn.dataTableExt.oSort, {
    "percent-pre": function(a) {
      var x;
      x = a === "-" ? 0 : a.replace(/%/, "");
      return parseFloat(x);
    },
    "percent-asc": function(a, b) {
      if (a < b) {
        return -1;
      } else if (a > b) {
        return 1;
      } else {
        return 0;
      }
    },
    "percent-desc": function(a, b) {
      if (a < b) {
        return 1;
      } else if (a > b) {
        return -1;
      } else {
        return 0;
      }
    }
  });

  jQuery(document).ready(function() {
    return jQuery('body').on('.tooltip.data-api');
  });

}).call(this);
