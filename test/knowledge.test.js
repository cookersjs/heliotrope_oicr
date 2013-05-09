var fs = require('fs'),
    mongo = require("mongodb"),
    MongoClient = mongo.MongoClient,
    knowledge = require("../lib/knowledge"),
    should = require('should');

function withDB(callback) {
  MongoClient.connect("mongodb://localhost:27017/heliotrope", function(err, db) {
    callback(db, err);
  });
}

describe('GET /genes/KRAS', function() {
  it('should retrieve a gene', function(done){
    withDB(function(db, err) {
      db.close();
      
      var request = {params: {gene: "KRAS"}};
      knowledge.getGene(request, function(db, err, result) {
        db.close();
        
        should.not.exist(err);
        result.data.name.should.equal("KRAS");
        result.data.url.should.equal("/genes/KRAS");
        done();
      });
    });
  });
});

describe('GET /genes/XXXXX', function() {
  it('should fail to retrieve a gene', function(done){
    withDB(function(db, err) {
      db.close();
      
      var request = {params: {gene: "XXXXX"}};
      knowledge.getGene(request, function(db, err, result) {
        db.close();
        
        should.exist(err);
        done();
      });
    });
  });
});

describe('GET /queries/frequencies', function() {
  it('should retrieve a set of gene frequencies', function(done){
    withDB(function(db, err) {
      db.close();
      
      var request = {params: {query: "frequencies"}};
      knowledge.executeQuery(request, function(db, err, result) {
        db.close();
        
        should.not.exist(err);
        result.data[0].name.should.equal('TTN');
        result.data[1].name.should.equal('JAK2');
        result.data[2].name.should.equal('TP53');
        done();
      });
    });
  });
});