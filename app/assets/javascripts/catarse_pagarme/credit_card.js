App.views.Pagarme.addChild('PaymentCard', _.extend({
  el: '#payment_type_credit_card_section form',

  events: {
    'keyup input[type="text"]' : 'creditCardInputValidator',
    'input #payment_card_number' : 'onKeyupPaymentCardNumber',
    'click input#credit_card_submit' : 'onSubmit',
    'change .creditcard-records' : 'onChangeCard',
    'blur input' : 'checkInput'
  },

  onChangeCard: function(event){
    var $target = $(event.currentTarget);
    $target.siblings().removeClass('selected');
    $target.addClass('selected');
    if($(event.target).val() == 0){
      this.$('.type_card_data').slideDown('slow');
    }
    else{
      this.$('.type_card_data').slideUp('slow');
    }
  },

  activate: function(options){
    var that = this;
    this.setupForm();
    this.message = this.$('.payment-error-message');
    this.formatCreditCardInputs();
    window.app.maskAllElements();
  },

  formatCreditCardInputs: function(){
    this.$('#payment_card_number').payment('formatCardNumber');
    this.$('#payment_card_date').payment('formatCardExpiry');
    this.$('#payment_card_source').payment('formatCardCVC');
  },

  getUrl: function(){
    var that = this;
    var url = '';

    if(that.$('input#payment_save_card').prop('checked') || that.hasSelectedSomeCard()) {
      url = '/payment/pagarme/'+that.parent.contributionId+'/pay_with_subscription';
    } else {
      url = '/payment/pagarme/'+that.parent.contributionId+'/pay_credit_card';
    }

    return url;
  },

  getAjaxType: function() {
    var type = 'POST';

    if(this.hasSelectedSomeCard()) {
      type = 'PUT'
    }
    return type;
  },

  selectedCard: function() {
    return this.$('input:radio[data-stored][name=payment_subscription_card]:checked');
  },

  hasSelectedSomeCard: function() {
    return this.selectedCard().length > 0;
  },

  getPaymentData: function() {
    var data = {};

    if(this.hasSelectedSomeCard()) {
      data = {
        subscription_id: this.selectedCard().val(),
        payment_card_installments: this.getInstallments() }
    } else {
      data = {
        payment_card_number: this.$('input#payment_card_number').val(),
        payment_card_name: this.$('input#payment_card_name').val(),
        payment_card_date: this.$('input#payment_card_date').val(),
        payment_card_source: this.$('input#payment_card_source').val(),
        payment_card_installments: this.getInstallments()
      }
    }

    return data;
  },

  getInstallments: function() {
    if(this.hasSelectedSomeCard()) {
      return this.$('.my-credit-cards .selected select#payment_card_installments').val();
    } else {
      return this.$('.type_card_data select#payment_card_installments').val();
    }
  },

  onSubmit: function(e) {
    var that = this;
    e.preventDefault();

    if(!this.validate()){
      return false;
    }

    $(e.currentTarget).hide();
    that.parent.loader.show();

    $.ajax({
      type: that.getAjaxType(),
      url: that.getUrl(),
      data: that.getPaymentData(),
      success: function(response){
        that.parent.loader.hide();

        if(response.payment_status == 'failed'){
          that.message.find('.message-text').html(response.message);
          that.message.slideDown('slow')

          $(e.currentTarget).show();
        } else {
          var thank_you = $('#project_review').data('thank-you-path');

          if(thank_you){
            location.href = thank_you;
          } else {
            location.href = '/';
          }
        }
      }
    });
  },

  onKeyupPaymentCardNumber: function(e){
    var number = $(e.currentTarget).val();
    this.$('#payment_card_flag').html(this.getCardFlag(number))
  },

  getCardFlag: function(number) {
    var flag = $.payment.cardType(number);
    return flag && flag.toUpperCase();
  }
}, Skull.Form));
