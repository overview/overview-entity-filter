/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
let ProgressView;
module.exports = (ProgressView = class ProgressView {
  constructor($el) {
    this.$el = $el;
    this.progress = 0;
  }

  render() {
    this.$el.html(`\
<progress max="1"></progress>
<small>Scanning all documents for entities…</small>\
`);

    this.$progress = this.$el.children('progress');

    return this;
  }

  setProgress(fraction) {
    this.$progress.attr('value', fraction);
    this.$el.toggleClass('done', fraction === 1);
    return this;
  }
});
