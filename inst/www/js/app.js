$(function() {
  
  var campaign_urn;
  var campaigndata = {};
  var today = new Date();
  var serverurl = location.protocol + "//" + location.host + "/app"
  
  function loadcampaign(){
    $("#surveyfield").empty();
    if(!campaign_urn) {
      $("#campaigngroup").addClass("has-error");
      return;
    }
    if(campaigndata[campaign_urn]){
      populatesurvey(campaigndata[campaign_urn]);
    } else {
      var mydata = {};
      oh.campaign.read(campaign_urn, "xml", function(res){
        var xml = $(jQuery.parseXML(res));
        $.each($("survey", xml), function(i, survey){
          var promptdata = {}
          var prompts = $(">contentList>prompt", survey);        
          $.each(prompts, function(i, prompt){
            var promptid = $(">id",prompt).text();
            promptdata[promptid] = {
              id : promptid,
              promptType : $(">promptType", prompt).text(),
              promptlabel : $(">displayLabel", prompt).text()
            };
          });
          var surveyid = $(">id", survey).text();
          mydata[surveyid] = {
            id : surveyid,
            title : $(">title", survey).text(),
            prompts : promptdata
          };
        });
        
        //recursive in case user changed selection in the mean time        
        campaigndata[campaign_urn] = mydata;
        loadcampaign();
      });
    }
  }
  
  function populatesurvey(mydata){
    $.each(mydata, function(i, survey){
      $("#surveyfield").append($("<option>").val(survey.id).text(survey.title));
    });
    populatevars();
  }
  
  function populatevars(){
    var mydata = campaigndata[campaign_urn];
    var surveyid = $("#surveyfield").val();
    $("#xfield").empty().append($("<option>").text("Date")).append($("<option>").text("Time"));
    $("#yfield").empty().append($("<option>"));
    $("#colorfield").empty().append($("<option>"));
    $("#sizefield").empty().append($("<option>"));   
    $("#facetfield").empty().append($("<option>"));     
    $.each(mydata[surveyid].prompts, function(i, val){
      if(val.promptType == "text" || val.promptType == "photo") return;
      $("#xfield").append($("<option>").val("prompt.id." + val.id).text(val.promptlabel));
      $("#yfield").append($("<option>").val("prompt.id." + val.id).text(val.promptlabel));  
      $("#colorfield").append($("<option>").val("prompt.id." + val.id).text(val.promptlabel));   
      $("#sizefield").append($("<option>").val("prompt.id." + val.id).text(val.promptlabel)); 
      $("#facetfield").append($("<option>").val("prompt.id." + val.id).text(val.promptlabel));        
    });
  }
  
  function getdata(cb){
    return opencpu.r_fun_call("getdata", {
      campaign_urn : campaign_urn,
      serverurl : serverurl,
      token : $.cookie("auth_token"),
      start_date : $("#fromfield").val(),
      end_date : $("#tofield").val()
    }, cb);
  }
  
  function makeplot(data){
    var args = {
      data : data,
      x : new opencpu.Snippet($("#xfield").val())
    };
    
    //setting optional arguments
    if($("#yfield").val()){
      args.y = new opencpu.Snippet($("#yfield").val());
    }
    
    if($("#colorfield").val()){
      args.color = new opencpu.Snippet($("#colorfield").val());
      args.fill = new opencpu.Snippet($("#colorfield").val());
    }    
    
    if($("#sizefield").val()){
      args.size = new opencpu.Snippet($("#sizefield").val());
    }        
    
    if($("#facetfield").val()){
      args.facets = new opencpu.Snippet("~" + $("#facetfield").val());
    }      
    
    return $("#plotdiv").r_fun_plot("makeplot", args);
  }
  
  $("#plotbutton").on("click", function(){
    if(!campaign_urn) {
      $("#campaigngroup").addClass("has-error");
      return;
    }
    
    $("#plotbutton").attr("disabled", "disabled");    
    var req1 = getdata(function(session){
      var req2 = makeplot(session).fail(function(){
        alert("Failed to make plot: " + req2.responseText);
      });
    }).fail(function(){
      alert("Failed to download data from Ohmage: " + req1.responseText);
      $("#plotbutton").removeAttr("disabled");
    }).done(function(){
      $("#plotbutton").removeAttr("disabled")
    });
  });
  
  $("#campaignfield").change(function(){
    campaign_urn = $("#campaignfield option:selected").val();
    if(campaign_urn){
      $("#campaigngroup").removeClass("has-error");
    }
    loadcampaign()
  })
  
  //init page
	oh.ping(function(){
		oh.user.whoami(function(x){
      $("#username").text(x);
      
      //populate campaign dropdown
			oh.user.info(function(data){
        $.each(data[x].campaigns, function(urn, title){
          $("#campaignfield").append($("<option>").text(title).attr("value", urn));
        });
        $("#campaignfield").val("");
			});
		});
	});
  
  $("#paramform .input-append.date").datepicker({format: "yyyy-mm-dd"});
  $("#tofield").val(today.getFullYear() + "-" + zeroFill(today.getMonth()+1, 2) + "-" + zeroFill(today.getDate(),2)); 
  $("#plotdiv").resizable();
  $("#surveyfield").change(populatevars);
  
});

function zeroFill( number, width ) {
  width -= number.toString().length;
  if ( width > 0 ) {
    return new Array( width + (/\./.test( number ) ? 2 : 1) ).join( '0' ) + number;
  }
  return number + ""; // always return a string
}
