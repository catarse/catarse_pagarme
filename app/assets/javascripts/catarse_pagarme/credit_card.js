App.views.PagarmeForm.addChild('PaymentCard', {
  el: '#payment_type_credit_card_section',

  events: {
    'keyup input[type="text"]' : 'creditCardInputValidator',
    'keyup #payment_card_number' : 'onKeyupPaymentCardNumber',
    'click input#credit_card_submit' : 'onSubmit',
  },

  onSubmit: function(e) {
    var that = this;
    e.preventDefault();
    $(e.currentTarget).hide();
    that.parent.loader.show();

    var data = {
      payment_card_number: this.$('input#payment_card_number').val(),
      payment_card_name: this.$('input#payment_card_name').val(),
      payment_card_date: this.$('input#payment_card_date').val(),
      payment_card_source: this.$('input#payment_card_source').val(),
      payment_card_installments: this.$('select#payment_card_installments').val()
    }

    $.post('/payment/pagarme/'+that.parent.contributionId+'/pay_credit_card', data).success(function(response){
      console.log(response);
      that.parent.loader.hide();

      if(response.payment_status == 'failed'){
        that.parent.message.find('p').html(response.message);
        that.parent.message.fadeIn('fast')

        $(e.currentTarget).show();
      } else {
        var thank_you = $('#project_review').data('thank-you-path');

        if(thank_you){
          location.href = thank_you;
        } else {
          location.href = '/';
        }
      }
    });
  },

  activate: function(options){
    // Set credit card fields masks
    this.pagarmeForm = this.parent;
    this.$('input#payment_card_date').mask('99/99');
    this.$('input#payment_card_birth').mask('99/99/9999');
    this.$('input#payment_card_cpf').mask("999.999.999-99");
    this.$('input#payment_card_phone').mask("(99) 9999-9999?9");
  },

  onKeyupPaymentCardNumber: function(e){
    this.$('input#payment_card_flag').val(this.getCardFlag($(e.currentTarget).val()))
  },

  getCardFlag: function(number) {
    var cc = (number + '').replace(/\s/g, ''); //remove space

    if ((/^(34|37)/).test(cc) && cc.length == 15) {
      return 'AmericanExpress'; //AMEX begins with 34 or 37, and length is 15.
    } else if ((/^(51|52|53|54|55)/).test(cc) && cc.length == 16) {
      return 'Mastercard'; //MasterCard beigins with 51-55, and length is 16.
    } else if ((/^(4)/).test(cc) && (cc.length == 13 || cc.length == 16)) {
      return 'Visa'; //VISA begins with 4, and length is 13 or 16.
    } else if ((/^(300|301|302|303|304|305|36|38)/).test(cc) && cc.length == 14) {
      return 'Diners'; //Diners Club begins with 300-305 or 36 or 38, and length is 14.
    } else if ((/^(38)/).test(cc) && cc.length == 19) {
      return 'Hipercard';
    }
    return 'Desconhecido';
  }
});
