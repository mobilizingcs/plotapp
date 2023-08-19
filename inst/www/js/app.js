$(function() {

  //some globals
  var campaigndata = {};
  var today = new Date();
  var serverurl = location.protocol + "//" + location.host + "/app";
  var campaign_urn = window.location.hash.replace(/^#/, "");

  function loadcampaign(){
    $("#surveyfield").empty();
    $("#subsetfield").val("");
    if(!campaign_urn) {
      $("#campaigngroup").addClass("has-error");
      return;
    }
    if(campaigndata[campaign_urn]){
      populatesurvey(campaigndata[campaign_urn]);
    } else if(campaign_urn.match("^urn:public")) {
      var demoname = campaign_urn.substring(11);
      var href = "/navbar/demo/data/" + demoname + "/" + demoname + "demo.xml";
      $.get(href, {}, loadxml, "text").fail(function() {
        alert("failed to download campaign from " + href);
      });
    } else {
      oh.campaign.read(campaign_urn, "xml", loadxml);
    }
  }
  
  function loadxml(txt){
    var mydata = {};
    var xml = $(jQuery.parseXML(txt));
    $.each($("survey", xml), function(i, survey){
      var promptdata = {};
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
    $("#sizefield").attr("disabled", "disabled");
    $(".fitclass").val("").attr("disabled", "disabled");
    $("#fitequation").prop("checked", false).attr("disabled", "disabled");

    /* Note: display the extract variable name in the text label because the
     * user needs to know the variable name to filter */
    $("#xfield").empty()
      .append($("<option>").text("date (yyyy-mm-dd)").val("date").attr("data-promptType", "number"))
      .append($("<option>").text("time (time of day)").val("time").attr("data-promptType", "number"))
      .append($("<option>").text("day (day of week)").val("day"))
      .append($("<option>").text("datetime").val("datetime").attr("data-promptType", "number"))
      .append($("<option>").text("user").val("user"))
      .append($("<option>").text("privacy").val("privacy"));

    $("#yfield").empty()
      .append($("<option>").val("").text("Responses (count)"))
      .append($("<option>").val("dotplot").text("Responses (dotplot)"));

    $("#colorfield").empty()
      .append($("<option>").val("").text("—"))
      .append($("<option>").text("user"))
      .append($("<option>").text("privacy"))
      .append($("<option>").text("day"));

    $("#sizefield").empty().append($("<option>").val("").text("—"));
    $("#facetfield").empty().append($("<option>").val("").text("—")).append($("<option>").text("user")).append($("<option>").text("privacy")).append($("<option>").text("day"));
    $.each(mydata[surveyid].prompts, function(i, val){
      if(val.promptType == "text" || val.promptType == "photo") return;
      $("#xfield").append($("<option>").val(val.id).text(val.id).attr("data-promptType", val.promptType)); //.text(val.promptlabel));
      $("#yfield").append($("<option>").val(val.id).text(val.id).attr("data-promptType", val.promptType));
      if(val.promptType == "number"){
        $("#sizefield").append($("<option>").val(val.id).text(val.id));
        var force_factor = "factor(" + val.id + ")";
        //comment out cause is confusing apparently
        //$("#xfield").append($("<option>").val(force_factor).text(force_factor).attr("data-promptType", val.promptType));
      }
      if(val.promptType == "single_choice"){
        $("#colorfield").append($("<option>").val(val.id).text(val.id));
        $("#facetfield").append($("<option>").val(val.id).text(val.id));
      }
    });
  }

  function disableinputs(e){
    if($("#yfield").val() && $("#yfield").val() != "dotplot") {
      $("#sizefield").removeAttr("disabled");
    } else {
      $("#sizefield").val("").attr("disabled", "disabled");
    }
    if($("#yfield option:selected").attr("data-promptType") == "number" && $("#xfield option:selected").attr("data-promptType") ==  "number"){
      $(".fitclass").removeAttr("disabled");
    } else {
      $(".fitclass").val("").attr("disabled", "disabled");
      $("#fitequation").prop("checked", false).attr("disabled", "disabled");
    }
  }

  function getdata(cb){
    return ocpu.call("getdata", {
      campaign_urn : campaign_urn,
      serverurl : serverurl,
      token : $.cookie("auth_token"),
      privacy_state : "shared",
      start_date : $("#fromfield").val() + " 00:00:00",
      end_date : $("#tofield").val() + " 23:59:59"
    }, cb);
  }

  function makeplot(data){
    var args = {
      data : data,
      x : $("#xfield").val()
    };

    //setting optional arguments
    if($("#yfield").val()) args.y = $("#yfield").val();
    if($("#colorfield").val()) args.fill = $("#colorfield").val();
    if($("#sizefield").val()) args.size = $("#sizefield").val();
    if($("#facetfield").val()) args.facet = $("#facetfield").val();
    if($("#subsetfield").val()) args.subset = $("#subsetfield").val();
    if($("#interceptfield").val() || $("#slopefield").val()){
      args.intercept = parseFloat($("#interceptfield").val()) || 0;
      args.slope = parseFloat($("#slopefield").val()) || 0;
    }
    if($("#fittypefield").val()) {
      args.fittype = $("#fittypefield").val();
      args.fitequation = $("#fitequation").prop("checked");
    }

    //chain it
    return $("#plotdiv").rplot("makeplot", args, function(session){
      session.getFile("summary.txt", function(txt){
        $("#summarydiv pre").empty().text(txt);
      });
    });
  }

  function errorbox(message){
    $("#alertdiv").append('<div id="alertbox" class="alert alert-danger alert-dismissable"> <button type="button" class="close" data-dismiss="alert" aria-hidden="true">&times;</button>' + message + '</div>');
  }

  $("#plotbutton").on("click", function(){
    if(!campaign_urn) {
      $("#campaigngroup").addClass("has-error");
      return;
    }

    $("#alertdiv").empty();
    $("#summarydiv pre").empty();

    $("#plotbutton").attr("disabled", "disabled");
    var req1 = getdata(function(session){
      var req2 = makeplot(session).fail(function(){
        errorbox("<strong>Failed to make plot</strong> " + req2.responseText.split("In call:")[0]);
      });
    }).fail(function(){
      errorbox("<strong>Failed to download data from Ohmage</strong> " + req1.responseText.split("In call:")[0]);
      $("#plotbutton").removeAttr("disabled");
    }).done(function(){
      $("#plotbutton").removeAttr("disabled");
    });
  });

  $("#campaignfield").change(function(){
    campaign_urn = $("#campaignfield option:selected").val();
    if(campaign_urn){
      $("#campaigngroup").removeClass("has-error");
    }
    loadcampaign();
  });

  $("#fittypefield").change(function(){
    if($("#fittypefield option:selected").val()){
      $("#fitequation").removeAttr("disabled");
    } else {
      $("#fitequation").prop("checked", false).attr("disabled", "disabled");
    }
  });

  $("#xfield").on("change", disableinputs);
  $("#yfield").on("change", disableinputs);

  //this is where we set the opencpu server in case it is hosted elsewhere
  if(!location.pathname.match("/library/plotbuilder")){
    ocpu.seturl("/ocpu/library/plotbuilder/R");
    if(location.host == "mobilize.lausd.net") {
      ocpu.seturl("https://mobilize.lausd.net/ocpu/library/plotbuilder/R/");
    }
  }

  //init page
  if(campaign_urn == "demo"){
    campaign_urn = $("#campaignfield option:selected").val();
    loadcampaign();
  } else if(campaign_urn.match("^urn:public")){
    loadcampaign();
    $("#plotappsubtitle").text(campaign_urn);
    $("#campaigngroup").hide();    
  } else {
  	oh.ping(function(){
  		oh.user.whoami(function(x){
        $("#username").text(x);
  
        //preselected campaign
        if(campaign_urn){
          loadcampaign();
          $("#campaigngroup").hide();
          oh.user.info(function(data){
            $("#plotappsubtitle").text(data[x].campaigns[campaign_urn] || campaign_urn);
          });
          return;
        }
  
        //populate campaign dropdown
  			oh.user.info(function(data){
          var campaigndata = $.map(data[x].campaigns, function(title, urn) {return [{urn:urn, title:title}]});
          campaigndata.sort(function(a,b){
            var nameA = a.title.toLowerCase();
            var nameB = b.title.toLowerCase();
            if (nameA < nameB) //sort string ascending
              return -1;
            if (nameA > nameB)
              return 1;
            return 0;
          });
          $.each(campaigndata, function(i, value){
            $("#campaignfield").append($("<option>").text(value.title).attr("value", value.urn));
          });
          $("#campaignfield").val(campaign_urn);
  			});
  
        //prevent timeouts while using the application
        oh.keepalive();
  		});
  	});
  }

  $("#paramform .input-append.date").datepicker({format: "yyyy-mm-dd"});
  $("#tofield").val(today.getFullYear() + "-" + zeroFill(today.getMonth()+1, 2) + "-" + zeroFill(today.getDate(),2));
  $("#plotdiv").resizable();
  $("#surveyfield").change(populatevars);

  $("input.fitclass").keyup(function(){
    $(this).val($(this).val().match(/-?[0-9]*[.]?[0-9]*/));
  });

});

function zeroFill( number, width ) {
  width -= number.toString().length;
  if ( width > 0 ) {
    return new Array( width + (/\./.test( number ) ? 2 : 1) ).join( '0' ) + number;
  }
  return number + ""; // always return a string
}
