$(function () {

  var client = new Faye.Client('/push', {timeout: 14});
  var subscription = client.subscribe('/updates', function(payload) {
    // Flash push marker
    $('#push').addClass("btn-success");
    setTimeout(removePushBreathe, 100);

    // Use the message
    handlePushMessage(payload);
  });

  // Subscription has been acknowledged by the server
  subscription.then(function() {
    $('#push').removeClass("btn-warning");
    $('#push').addClass("btn-primary");
  });

});

function handlePushMessage(msg) {

  switch(msg.what) {
    case "!queue":
      updateQueue(msg);
      break;
    case "!progress":
      updateJobProgress(msg);
      break;
    case "job":
      updateJobRow(msg);
      break;
    default:
      // alert(msg.what);
    }

  }

function removePushBreathe() {
  $('#push').removeClass("btn-success");
  // updatePushMsg('-');
  }

function updatePushMsg(msg) {
  $('#pushmsg').html(msg);
  }

function updateJobProgress(msg) {
  updatePushMsg(msg.id+ ' progress');

  job = $('#'+msg.key);
  job.find('.push-progress').html(msg.progress);
  job.find('.push-bitrate').html(msg.bitrate);
  job.find('.push-filename').html(msg.filename);
  job.find('.progress-bar').width(msg.progress);
  }

function updateJobRow(msg) {
  updatePushMsg(msg.id+ ' updated');
  $.get( "/jobs/"+msg.id, function( html ) {
    $('#'+msg.key).replaceWith(html);
    });
  }

function updateQueue(msg) {
  updatePushMsg('queue updated');
  var qs = window.location.search;
  $.get( "/jobs/"+qs, function( html ) {
    $('#box-jobs').html(html);
    });
  }

