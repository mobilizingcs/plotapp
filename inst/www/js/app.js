$(function() {

  //some globals
  var campaign_urn;
  var campaigndata = {};
  var today = new Date();
  var serverurl = location.protocol + "//" + location.host + "/app"

  function loadcampaign(){
    $("#surveyfield").empty();
    $("#subsetfield").val("");
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
    $("#sizefield").attr("disabled", "disabled");
    $(".fitclass").val("").attr("disabled", "disabled");
    $("#fitequation").prop("checked", false).attr("disabled", "disabled");

    $("#xfield").empty()
      .append($("<option>").text("date").attr("data-promptType", "number"))
      .append($("<option>").text("time").attr("data-promptType", "number"))
      .append($("<option>").text("day"))
      .append($("<option>").text("datetime").attr("data-promptType", "number"))
      .append($("<option>").text("user"))
      .append($("<option>").text("privacy"));

    $("#yfield").empty()
      .append($("<option>").val("").text("responses (count)"))
      .append($("<option>").val("dotplot").text("responses (dotplot)"));

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
      start_date : $("#fromfield").val(),
      end_date : $("#tofield").val()
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
    if($("#interceptfield").val()){
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
    $("#summarydiv pre").empty()

    $("#plotbutton").attr("disabled", "disabled");
    var req1 = getdata(function(session){
      var req2 = makeplot(session).fail(function(){
        errorbox("<strong>Failed to make plot</strong> " + req2.responseText.split("In call:")[0]);
      });
    }).fail(function(){
      errorbox("<strong>Failed to download data from Ohmage</strong> " + req1.responseText.split("In call:")[0]);
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

  $("#fittypefield").change(function(){
    if($("#fittypefield option:selected").val()){
      $("#fitequation").removeAttr("disabled");
    } else {
      $("#fitequation").prop("checked", false).attr("disabled", "disabled");
    }
  })

  $("#xfield").on("change", disableinputs);
  $("#yfield").on("change", disableinputs);

  //init page
	oh.ping(function(){
		oh.user.whoami(function(x){
      $("#username").text(x);

      //this is where we set the opencpu server in case it is hosted elsewhere
      if(!location.pathname.match("/library/plotbuilder")){
        ocpu.seturl("/ocpu/library/plotbuilder/R");
      }

      //populate campaign dropdown
			oh.user.info(function(data){
        var campaigndata = $.map(data[x].campaigns, function(title, urn) {return [{urn:urn, title:title}]});
        campaigndata.sort(function(a,b){
          var nameA = a.title.toLowerCase();
          var nameB = b.title.toLowerCase();
          if (nameA < nameB) //sort string ascending
            return -1
          if (nameA > nameB)
            return 1
          return 0
        });
        $.each(campaigndata, function(i, value){
          $("#campaignfield").append($("<option>").text(value.title).attr("value", value.urn));
        });
        $("#campaignfield").val("");
			});

      //prevent timeouts while using the application
      oh.keepalive();
		});
	});

  $("#paramform .input-append.date").datepicker({format: "yyyy-mm-dd"});
  $("#tofield").val(today.getFullYear() + "-" + zeroFill(today.getMonth()+1, 2) + "-" + zeroFill(today.getDate(),2));
  $("#plotdiv").resizable();
  $("#surveyfield").change(populatevars);

  $("input.fitclass").keyup(function(){
    $(this).val($(this).val().match(/-?[0-9]+[.]?[0-9]*/));
  });

});

function zeroFill( number, width ) {
  width -= number.toString().length;
  if ( width > 0 ) {
    return new Array( width + (/\./.test( number ) ? 2 : 1) ).join( '0' ) + number;
  }
  return number + ""; // always return a string
}
