const { defaults } = require('jest-config');

module.exports = {
  moduleFileExtensions: ["js", "wat", ...defaults.moduleFileExtensions],
};