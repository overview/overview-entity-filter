/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS201: Simplify complex destructure assignments
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
let FilterView;
const $ = require('jquery');
const template = require('lodash.template');

const Filters = require('../../server/Filters');

module.exports = (FilterView = (function() {
  FilterView = class FilterView {
    static initClass() {
  
      this.prototype.events = [
        [ 'click', 'button.unblacklist', '_onClickUnblacklist' ],
        [ 'change', 'input', '_onChange' ],
        [ 'submit', 'form', '_onSubmit' ]
      ];
  
      this.prototype.templates = {
        main: template(`\
<form method="post" action="#">
  <div class="include">
    <h3>Search for only these:</h3>
    <ul class="filters"><%= includeFiltersHtml %></ul>
  </div>
  <div class="exclude">
    <h3>… then remove any of these:</h3>
    <ul class="filters"><%= excludeFiltersHtml %></ul>
  </div>
  <div class="blacklist hide">
    <h3>… and omit these, too:</h3>
    <ul class="tokens"></ul>
  </div>
</form>\
`),
  
        filter: template(`\
<li class="filter" data-filter-id="<%- filter.id %>">
  <label>
    <input type="checkbox" name="<%- includeOrExclude %>:<%- filter.id %>" >
    <strong><%- filter.name %></strong>
    <span class="description"><%= filter.descriptionHtml %></span>
  </label>
</li>\
`),
  
        blacklistItem: template(`\
<li class="token">
  <button class="unblacklist" type="button" title="Un-hide this entity" data-token-name="<%- tokenName %>">❌</button>
  <span class="name"><%- tokenName %></span>
</li>\
`)
      };
    }
    constructor($el, options) {
      this.$el = $el;
      this.options = options;
      if (!('blacklist' in this.options)) { throw new Error('Must set options.blacklist, a Blacklist'); }
      if (!('filters' in this.options)) { throw new Error('Must set options.filters, an Object'); }
      if (!('onSelectFilters' in this.options)) { throw new Error('Must set options.onSelectFilters, a callback'); }

      this.events.forEach((...args) => {
        const [ ev, selector, callback ] = Array.from(args[0]);
        return this.$el.on(ev, selector, (...args) => this[callback](...Array.from(args || [])));
      });

      this.options.blacklist.on('change', () => this._renderBlacklist());
    }

    // Resets the filters which are selected.
    //
    // This does not emit any signals. Rather, it sets some inputs to checked and
    // sets others to unchecked.
    // unchecks the others.
    setFilters(filters) {
      let filterId;
      this.$el.find('input[type=checkbox]').prop('checked', false);

      for (filterId of Array.from(filters.include)) {
        this.$el.find(`[name=\"include:${filterId}\"]`).prop('checked', true);
      }
      for (filterId of Array.from(filters.exclude)) {
        this.$el.find(`[name=\"exclude:${filterId}\"]`).prop('checked', true);
      }

      this._renderSelected();

      return this;
    }

    render() {
      let f;
      const allFilters = ((() => {
        const result = [];
        for (let __ in Filters) {
          f = Filters[__];
          result.push(f);
        }
        return result;
      })()).sort((a, b) => a.name.localeCompare(b.name));

      const includeFiltersHtml = ((() => {
        const result1 = [];
        for (f of Array.from(allFilters)) {           if (f.canInclude) {
            result1.push(this.templates.filter({filter: f, includeOrExclude: 'include'}));
          }
        }
        return result1;
      })()).join('');
      const excludeFiltersHtml = ((() => {
        const result2 = [];
        for (f of Array.from(allFilters)) {           if (f.canExclude) {
            result2.push(this.templates.filter({filter: f, includeOrExclude: 'exclude'}));
          }
        }
        return result2;
      })()).join('');

      const html = this.templates.main({
        includeFiltersHtml,
        excludeFiltersHtml
      });

      this.$el.html(html);

      this.setFilters(this.options.filters);

      this._renderSelected();
      this._renderBlacklist();

      return this;
    }

    // Sets each li class to "selected" iff it is selected
    _renderSelected() {
      this.$el.find('li').removeClass('selected');
      return this.$el.find('input:checked').closest('li').addClass('selected');
    }

    // Re-renders the blacklist
    _renderBlacklist() {
      const blacklistHtml = (Array.from(this.options.blacklist.toArray()).map((t) => this.templates.blacklistItem({tokenName: t}))).join('');

      return this.$el.find('.blacklist')
        .toggleClass('hide', blacklistHtml.length === 0)
        .find('ul.tokens').html(blacklistHtml);
    }

    _callSetter() {
      const filters = {
        include: [],
        exclude: []
      };

      for (let value of Array.from(this.$el.find('form').serializeArray())) {
        const m = /(include|exclude):(.*)/.exec(value.name);
        filters[m[1]].push(m[2]);
      }

      return this.options.onSelectFilters(filters);
    }

    _onSubmit(e) {
      e.preventDefault();
      return this._callSetter();
    }

    // If complementName is "include:geonames", uncheck "exclude:geonames"
    _ensureUnchecked(complementName) {
      const reverse = {
        include: 'exclude',
        exclude: 'include'
      };
      const m = /(include|exclude):(.*)/.exec(complementName);

      const name = `${reverse[m[1]]}:${m[2]}`;
      return this.$el.find(`input[name=\"${name}\"]`).prop('checked', false);
    }

    _onChange(e) {
      const name = e.currentTarget.getAttribute('name');
      this._ensureUnchecked(name);
      this._renderSelected();
      return this._callSetter();
    }

    _onClickUnblacklist(e) {
      const tokenName = e.currentTarget.getAttribute('data-token-name');
      return this.options.blacklist.remove(tokenName);
    }
  };
  FilterView.initClass();
  return FilterView;
})());
