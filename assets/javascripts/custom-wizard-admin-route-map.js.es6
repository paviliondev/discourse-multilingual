export default {
  resource: 'admin',
  map() {
    this.route('adminMultilingual', { path: '/multilingual', resetNamespace: true }, function() {
      this.route('adminMultilingualLanguages', { path: '/languages', resetNamespace: true });
    });
  }
};
