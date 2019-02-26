/**
* @author Alejandro Galue <agalue@opennms.org>
* @copyright 2014 The OpenNMS Group, Inc.
*/

const RequisitionService = require('./RequisitionService');
const _ = require('lodash');

/**
* @ngdoc object
* @name RequisitionInterface
* @module onms-requisitions
* @param {Object} intf an OpenNMS interface JSON object
* @constructor
*/
const RequisitionInterface = function RequisitionInterface(intf) {
  'use strict';

  const self = this;

  /**
   * @description The IP Address of the interface
   * @ngdoc property
   * @name RequisitionInterface#ipAddress
   * @propertyOf RequisitionInterface
   * @returns {string} The IP Address of the interface
   */
  self.ipAddress = intf['ip-addr'];

  /**
   * @description The description of the interface
   * @ngdoc property
   * @name RequisitionInterface#description
   * @propertyOf RequisitionInterface
   * @returns {string} The description of the interface
   */
  self.description = intf['descr'];

  /**
   * @description The primary flag ('P' for primary, 'S' for secondary or 'N' for None)
   * @ngdoc property
   * @name RequisitionInterface#snmpPrimary
   * @propertyOf RequisitionInterface
   * @returns {string} The primary flag
   */
  self.snmpPrimary = intf['snmp-primary'];

  /**
   * @description The status of the interface (managed or unmanaged)
   * @ngdoc property
   * @name RequisitionInterface#status
   * @propertyOf RequisitionInterface
   * @returns {string} The status
   */
  self.status = 'managed';
  if (intf && intf['status']) {
    self.status = intf['status'] === '1' ? 'managed' : 'unmanaged';
  }


  /**
   * @description The array of services. Each service is an object with a name property, for example: { name: 'ICMP' }
   * @ngdoc property
   * @name RequisitionInterface#services
   * @propertyOf RequisitionInterface
   * @returns {array} The services
   */
  self.services = [];

  angular.forEach(intf['monitored-service'], function(svc) {
    self.services.push(new RequisitionService(svc));
  });

  /**
   * @description The array of requisition metaData entries
   * @ngdoc property
   * @name RequisitionNode#requisitionMetaData
   * @propertyOf RequisitionNode
   * @returns {object} The requisition metaData entries
   */
  self.requisitionMetaData = [];

  /**
   * @description The array of other metaData entries
   * @ngdoc property
   * @name RequisitionNode#otherMetaData
   * @propertyOf RequisitionNode
   * @returns {object} The other metaData entries
   */
  self.otherMetaData = {};

  angular.forEach(intf['meta-data'], function(entry) {
    if (entry.context === 'requisition') {
      self.requisitionMetaData.push({
        'key': entry.key,
        'value': entry.value,
      });
    } else {
      if (!_.has(self.otherMetaData, entry.context)) {
        self.otherMetaData[entry.context] = []
      }
      self.otherMetaData[entry.context].push({
        'key': entry.key,
        'value': entry.value,
      });
    }
  });

  self.className = 'RequisitionInterface';

  return self;
};

module.exports = RequisitionInterface;
