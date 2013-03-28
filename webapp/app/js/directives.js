// Generated by CoffeeScript 1.6.2
(function() {
  angular.module('heliotrope.directives', []).directive('appVersion', [
    'version', function(version) {
      return function(scope, elm, attrs) {
        return elm.text(version);
      };
    }
  ]).directive('heliStepField', function($compile, Entities) {
    var result;

    return result = {
      restrict: "A",
      replace: true,
      transclude: true,
      scope: true,
      locals: {
        "fieldKey": 'bind',
        "fieldValue": 'bind'
      },
      template: '<div class="controls">' + '</div>',
      link: function(scope, iElement, iAttrs, controller) {
        return scope.$watch('fieldValue', function(newValue, oldValue) {
          var body, chooser, linkFn, template,
            _this = this;

          if (newValue) {
            switch (newValue.controlType) {
              case "text":
                body = '<input type="text" id="{{fieldKey}}" ng-model="fieldValue.value" placeholder="{{fieldValue.label}}">';
                template = angular.element(body);
                linkFn = $compile(template);
                return iElement.append(linkFn(scope));
              case "select":
                body = '<select ng-model="fieldValue.value"><option ng-repeat="value in fieldValue.range">{{value}}</option></select>';
                template = angular.element(body);
                linkFn = $compile(template);
                return iElement.append(linkFn(scope));
              case "date":
                body = '<input type="text" class="datepicker" ng-model="fieldValue.value" id="{{fieldKey}}" placeholder="{{fieldValue.label}}">';
                template = angular.element(body);
                linkFn = $compile(template);
                iElement.append(linkFn(scope));
                return jQuery(iElement.find(".datepicker")).datepicker({
                  autoclose: true
                });
              case "checkbox":
                body = '<input type="checkbox" ng-model="fieldValue.value" id="{{fieldKey}}">';
                template = angular.element(body);
                linkFn = $compile(template);
                return iElement.append(linkFn(scope));
              case "chooser":
                body = '<input type="text" class="chooser" ng-model="fieldValue.value" id="{{fieldKey}}" autocomplete="off"></input>';
                template = angular.element(body);
                linkFn = $compile(template);
                iElement.append(linkFn(scope));
                chooser = jQuery(iElement.find(".chooser"));
                chooser.typeahead({
                  source: function(query, callback) {
                    var entities, entity, role, studyName;

                    entity = scope.$eval('entity');
                    studyName = entity.data.study.name;
                    role = newValue.entity;
                    return entities = Entities.get({
                      study: studyName,
                      role: role,
                      q: "^" + query
                    }, function() {
                      var entry;

                      callback((function() {
                        var _i, _len, _ref, _results;

                        _ref = entities.data;
                        _results = [];
                        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
                          entry = _ref[_i];
                          _results.push(entry.identity);
                        }
                        return _results;
                      })());
                      return false;
                    });
                  },
                  matcher: function(item) {
                    return true;
                  }
                });
                return jQuery(document).on('mousedown', 'ul.typeahead', function(e) {
                  return e.preventDefault();
                });
              default:
                return console.log("Unknown control type", newValue);
            }
          }
        });
      }
    };
  }).directive('heliWorkflows', function() {
    var result;

    return result = {
      restrict: "A",
      replace: true,
      transclude: true,
      template: '<ul class="dropdown-menu">' + '<li ng-repeat="step in entity.data.availableSteps">' + '<a href="{{step.url}}">{{step.label}}</a>' + '</li>' + '</ul>'
    };
  }).directive('heliReference', function() {
    var result;

    return result = {
      restrict: "A",
      replace: true,
      transclude: true,
      scope: 'isolate',
      locals: {
        reference: 'bind'
      },
      template: '<a href="http://www.ncbi.nlm.nih.gov/pubmed/{{reference.id}}" rel="external">{{reference.type}}:{{reference.id}}</a>'
    };
  }).directive('heliField', function() {
    var result;

    return result = {
      restrict: "A",
      replace: true,
      link: function(scope, iElement, iAttrs, controller) {
        return scope.$watch('entity', function(newValue, oldValue) {
          var field;

          field = newValue.getField(iAttrs.name);
          if (field) {
            return jQuery(iElement).text(field.displayValue);
          } else {
            return jQuery(iElement).text("N/A");
          }
        });
      }
    };
  }).directive('heliTab', function() {
    var result;

    return result = {
      restrict: "A",
      replace: true,
      transclude: true,
      template: '<ul class="nav nav-tabs">' + '<li class="active"><a href="#tab1" data-toggle="tab">Summary</a></li>' + '<li><a href="#tab2" data-toggle="tab">Enrolment</a></li>' + '<li><a href="#tab3" data-toggle="tab">Samples</a></li>' + '<li><a href="#tab4" data-toggle="tab">Clinical history</a></li>' + '<li><a href="#tab5" data-toggle="tab">Results</a></li>' + '<li><a href="#tab6" data-toggle="tab">Reports</a></li>' + '<li><a href="#tab7" data-toggle="tab">Panel decision</a></li>' + '<li><a href="#tab8" data-toggle="tab">Log</a></li>' + '</ul>',
      link: function(scope, iElement, iAttrs, controller) {
        return jQuery(iElement).find("a").click(function(e) {
          e.preventDefault();
          e.stopPropagation();
          return jQuery(this).tab('show');
        });
      }
    };
  }).directive('heliDynatab', function($compile, Views) {
    var result;

    return result = {
      restrict: "A",
      replace: true,
      transclude: true,
      template: '<div class="tabbable tabs-left"><ul class="nav nav-tabs"></ul><div class="tab-content"></div></div>',
      link: function(scope, iElement, iAttrs, controller) {
        return scope.$watch('entity.data', function(newValue, oldValue) {
          var contentElement, element, menuElement, name, role, views;

          if (newValue) {
            role = newValue.role;
            name = newValue.study.name;
            element = jQuery(iElement);
            menuElement = element.find(".nav");
            contentElement = element.find(".tab-content");
            return views = Views.get({
              study: name,
              role: role
            }, function() {
              var active, body, link, linkFn, template, view, _i, _len, _ref, _results;

              active = "active";
              _ref = views.data;
              _results = [];
              for (_i = 0, _len = _ref.length; _i < _len; _i++) {
                view = _ref[_i];
                link = jQuery('<li class="' + active + '"><a href="#' + view.name + '" data-toggle="tab">' + view.label["default"] + '</a></li>');
                link.appendTo(menuElement);
                link.find("a").click(function(e) {
                  e.preventDefault();
                  e.stopPropagation();
                  return jQuery(this).tab('show');
                });
                body = '<div class="tab-pane ' + active + '" id="' + view.name + '">' + view.body + '</div>';
                active = "";
                template = angular.element(body);
                linkFn = $compile(template);
                _results.push(contentElement.append(linkFn(scope)));
              }
              return _results;
            });
          }
        });
      }
    };
  }).directive('heliFrequencies', function() {
    var result;

    result = {
      restrict: "A",
      replace: true,
      transclude: true,
      scope: false,
      template: '<table class="table table-bordered table-striped table-condensed">' + '<thead>' + '<tr>' + '<th>Tumour type</th>' + '<th>Frequency</th>' + '</tr>' + '</thead>' + '<tbody>' + '</tbody>' + '</table>',
      link: function(scope, iElement, iAttrs, controller) {
        return scope.$watch('gene.data.sections.frequencies.data.tumour', function(newValue, oldValue) {
          var renderPercent;

          if (newValue) {
            renderPercent = function(x) {
              var formatter;

              formatter = new NumberFormat(x.frequency * 100.0);
              formatter.setPlaces(2);
              return '<b>' + formatter.toFormatted() + "%" + '</b> (' + x.affected + ' of ' + x.total + ' samples)';
            };
            return jQuery(iElement).dataTable({
              sPaginationType: "bootstrap",
              bPaginate: true,
              aaData: newValue,
              aoColumns: [
                {
                  "sTitle": "Tumour type",
                  "sClass": "span8",
                  "mData": "tumourTypesRefx.name"
                }, {
                  "sTitle": "Frequency",
                  "sClass": "span4",
                  "mData": renderPercent,
                  "sType": "percent"
                }
              ],
              aaSorting: [[1, "desc"]]
            });
          }
        });
      }
    };
    return result;
  }).directive('heliStructureDistribution', function() {
    var result;

    return result = {
      restrict: "A",
      replace: true,
      transclude: true,
      scope: false,
      template: '<div class="diagram"></div>',
      link: function(scope, iElement, iAttrs, controller) {
        return scope.$watch('gene.data', function(newValue, oldValue) {
          var availableWidth, chart, chartHeight, chartWidth, codon, colorDomainFunction, data, display, domainColours, domainGroups, domains, element, h, heightDomainFunction, heightFunction, identity, leftMargin, maximumValue, rightMargin, textDomainFunction, transcript, variantData, variantPositionData, w, widthDomainFunction, widthFunction, x, xAxis, xCodon, xOffsetDomainFunction, xOffsetFunction, y, yOffsetDomainFunction, yOffsetFunction,
            _this = this;

          if (newValue) {
            display = jQuery(iElement);
            chartWidth = 700;
            chartHeight = 140;
            element = display.get()[0];
            chart = d3.select(element).append("svg").attr("class", "chart").attr("width", chartWidth).attr("height", chartHeight);
            data = newValue.sections.distribution.data;
            transcript = newValue.sections.transcripts.data.records[0];
            maximumValue = Math.max.apply(Math, data);
            leftMargin = 20;
            rightMargin = 10;
            availableWidth = chartWidth - leftMargin - rightMargin;
            w = availableWidth / data.length;
            h = 100;
            x = d3.scale.linear().domain([0, 200]).range([leftMargin, availableWidth + leftMargin]);
            y = d3.scale.linear().domain([0, maximumValue]).rangeRound([0, h]);
            xCodon = d3.scale.linear().domain([0, transcript.lengthAminoAcid]).range([leftMargin, availableWidth + leftMargin]);
            xOffsetFunction = function(d, i) {
              return x(i) + 0.5;
            };
            yOffsetFunction = function(d) {
              return h - y(d) - 0.5;
            };
            widthFunction = function(d) {
              return w + 1;
            };
            heightFunction = function(d) {
              return y(d);
            };
            identity = function(x) {
              return x;
            };
            chart.selectAll("rect.frequency").data(data).enter().append("rect").attr("class", "frequency").attr("x", xOffsetFunction).attr("y", yOffsetFunction).attr("width", widthFunction).attr("height", heightFunction);
            xAxis = d3.svg.axis();
            xAxis.scale(xCodon);
            xAxis.orient("bottom");
            chart.append("g").attr("class", "axis").attr("transform", "translate(0," + (h - 0.5) + ")").call(xAxis);
            variantData = void 0;
            if (variantData) {
              variantPositionData = variantData.get("data")["sections"]["positions"];
              if (variantPositionData) {
                codon = variantPositionData.data[0].codon;
                if (codon) {
                  codon = codon.replace(/(?:-\d+)$/, "");
                  chart.append("line").attr("x1", xCodon(codon)).attr("x2", xCodon(codon)).attr("y1", h - 0.5).attr("y2", h - 20 + 0.5).attr("stroke", "#000").attr("stroke-width", 2);
                  chart.append("circle").attr("cx", xCodon(codon)).attr("cy", h - 20 + 0.5).attr("r", 7).attr("fill", "#c55");
                }
              }
            }
            domains = (function() {
              var _i, _len, _ref, _results;

              _ref = transcript.domains;
              _results = [];
              for (_i = 0, _len = _ref.length; _i < _len; _i++) {
                element = _ref[_i];
                if (element.gffSource === "Pfam") {
                  _results.push(element);
                }
              }
              return _results;
            })();
            xOffsetDomainFunction = function(d, i) {
              return xCodon(d.start) - 0.5;
            };
            yOffsetDomainFunction = function(d) {
              return h + 24 - 0.5;
            };
            widthDomainFunction = function(d) {
              return xCodon(d.end) - xCodon(d.start) - 0.5;
            };
            heightDomainFunction = function(d) {
              return 12;
            };
            textDomainFunction = function(d) {
              return d.description;
            };
            domainColours = d3.scale.category10();
            colorDomainFunction = function(d, i) {
              return domainColours(i);
            };
            domainGroups = chart.selectAll("g.domain").data(domains).enter().append("g").attr("class", "domain");
            domainGroups.append("rect").attr("x", xOffsetDomainFunction).attr("y", yOffsetDomainFunction).attr("width", widthDomainFunction).attr("height", heightDomainFunction).attr("rel", "tooltip").attr("title", textDomainFunction).style("fill", colorDomainFunction);
            return display.find("g.domain rect").tooltip({
              container: "body"
            });
          }
        });
      }
    };
  }).directive('heliGeneFrequencies', function() {
    var result;

    return result = {
      restrict: "A",
      replace: true,
      transclude: true,
      scope: false,
      template: '<div class="diagram"></div>',
      link: function(scope, iElement, iAttrs, controller) {
        return scope.$watch('gene.data', function(newValue, oldValue) {
          var chartHeight, chartWidth, data, display, element, formatPercent, height, margin, node, svg, width, x, xAxis, y, yAxis;

          if (newValue) {
            display = jQuery(iElement);
            data = newValue.slice(0, 30);
            chartWidth = 760;
            chartHeight = 600;
            margin = {
              top: 20,
              right: 20,
              bottom: 30,
              left: 80
            };
            width = chartWidth - margin.left - margin.right;
            height = chartHeight - margin.top - margin.bottom;
            formatPercent = d3.format(".0%");
            x = d3.scale.linear().range([0, width]);
            y = d3.scale.ordinal().rangeRoundBands([0, height], 0.1);
            xAxis = d3.svg.axis().scale(x).orient("top").tickFormat(formatPercent);
            yAxis = d3.svg.axis().scale(y).orient("left");
            x.domain([
              0, d3.max(data, function(d) {
                return d.frequency.frequency;
              })
            ]);
            y.domain(data.map(function(d) {
              return d.name;
            }));
            element = display.get()[0];
            svg = d3.select(element).append("svg").attr("class", "chart").attr("width", width + margin.left + margin.right).attr("height", height + margin.top + margin.bottom).append("g").attr("transform", "translate(" + margin.left + "," + margin.top + ")");
            svg.append("g").attr("class", "x axis").call(xAxis);
            svg.append("g").attr("class", "y axis").call(yAxis).append("text").attr("transform", "rotate(-90)").attr("y", 6).attr("dy", ".71em");
            node = svg.selectAll(".bar").data(data).enter().append("a").attr("xlink:href", function(d) {
              return "genes/" + d.name;
            });
            return node.append("rect").attr("class", "bar").attr("x", 0.5).attr("y", function(d) {
              return y(d.name);
            }).attr("width", function(d) {
              return x(d.frequency.frequency);
            }).attr("height", y.rangeBand());
          }
        });
      }
    };
  });

}).call(this);
