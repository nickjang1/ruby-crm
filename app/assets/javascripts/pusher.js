$(document).ready(function(){
  var current_user_id = $("body").data('user-id');

  if (current_user_id) {

    var alertNotification = function() {
      $("#header-notifications #notification-icon").removeClass('hidden');
    };

    var pusher = new Pusher('86d055f43ac176272b01');

    var fax_channel = pusher.subscribe('fax_channel');
    fax_channel.bind('sending', function(data) {
      if (current_user_id != data.to) {
        return;
      }
      alertMessage = data.message;
      $.gritter.add({
        time: 5000, 
        text: "Purchase Order " + data.po_number + ": " + alertMessage, 
        class_name: "alert alert-success"
      });
    });
    

    fax_channel.bind('failed', function(data) {
      if (current_user_id != data.to) {
        return;
      }
      if (data.po_number) {
        alertNotification();

        alertMessage = data.message;
        $.gritter.add({
          time: 5000, 
          text: "Purchase Order " + data.po_number + ": " + alertMessage, 
          class_name: "alert alert-danger"
        });
      }
    });

    fax_channel.bind('success', function(data) {
      if (current_user_id != data.to) {
        return;
      }
      if (data.po_number) {
        alertNotification();
        alertMessage = data.message;
        $.gritter.add({
          time: 5000, 
          text: "Purchase Order " + data.po_number + ": " + alertMessage, 
          class_name: "alert alert-success"
        });
      }
    });

    var request_channel = pusher.subscribe('request_channel');
    request_channel.bind('request.approve', function(data) {
      if (current_user_id == data.to) {
        alertMessage = data.message;
        $.gritter.add({
          time: 5000, 
          text: alertMessage, 
          class_name: "alert alert-success"
        });
      }
    });

    request_channel.bind('request.approve.received', function(data) {
      if ($.inArray(current_user_id, data.to) != -1) {
        alertMessage = data.message;
        $.gritter.add({
          time: 5000, 
          text: alertMessage, 
          class_name: "alert alert-info"
        });
        alertNotification();
      }
    });

    request_channel.bind('request.checked', function(data) {
      if (current_user_id == data.to) {
        class_name = 'alert ';
        if (data.state == 'approved') {
          class_name += 'alert-success';
        }
        else if (data.state == 'rejected') {
          class_name += 'alert-danger'
        }
        alertMessage = data.message;
        $.gritter.add({
          time: 5000, 
          text: alertMessage, 
          class_name: class_name
        });
        alertNotification();
      }
    });
    
    var work_order_channel = pusher.subscribe('work_order_channel');
    
    work_order_channel.bind('notification.send', function(data) {
        
      if (current_user_id != data.to) {
        return;
      }
      alertMessage = data.message;
      
      $.gritter.add({
        time: 5000, 
        text: alertMessage, 
        class_name: "alert alert-success"
      });
    });

  }
})