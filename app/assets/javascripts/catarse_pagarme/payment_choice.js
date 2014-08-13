App.views.PagarmeForm.addChild('PaymentChoice', {
  el: '.list_payment',

  events: {
    'change input[type="radio"]' : 'onListPaymentChange'
  },

  onListPaymentChange: function(e){
    var that = this.parent;

    $('.payment_section').fadeOut('fast', function(){
      var currentElementId = $(e.currentTarget).attr('id');
      that.$('#'+currentElementId+'_section').fadeIn('fast');
    });
  },

  activate: function(){
    var that = this.parent;

    that.$('input#payment_type_credit_card').click();
  }
});
