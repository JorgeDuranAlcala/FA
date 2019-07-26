# reliable cost change log in stock_moves
ALTER TABLE `0_stock_moves` CHANGE COLUMN `standard_cost` `unit_cost` double NOT NULL DEFAULT '0';
ALTER TABLE `0_debtor_trans_details` CHANGE COLUMN `standard_cost` `unit_cost` double NOT NULL DEFAULT '0';

# naming cleanups
ALTER TABLE `0_purch_orders` CHANGE COLUMN `requisition_no` `supp_reference` tinytext;

# cleanups in work orders
ALTER TABLE  `0_workorders` DROP INDEX `wo_ref`;
ALTER TABLE  `0_workorders` ADD KEY `wo_ref` (`wo_ref`);
ALTER TABLE  `0_workorders` DROP COLUMN `additional_costs`;

# improvements in tax systems support
ALTER TABLE `0_stock_category` ADD COLUMN  `vat_category` tinyint(1) NOT NULL DEFAULT '0' AFTER `dflt_no_purchase`;
ALTER TABLE `0_stock_master` ADD COLUMN  `vat_category` tinyint(1) NOT NULL DEFAULT '0' AFTER `fa_class_id`;
ALTER TABLE `0_trans_tax_details` ADD COLUMN  `vat_category` tinyint(1) NOT NULL DEFAULT '0' AFTER `reg_type`;
ALTER TABLE `0_trans_tax_details` ADD COLUMN `tax_group_id` int(11) DEFAULT NULL AFTER `vat_category`;

UPDATE `0_trans_tax_details` tax
	LEFT JOIN `0_supp_trans` purch ON tax.trans_no=purch.trans_no AND tax.trans_type=purch.type
	LEFT JOIN `0_suppliers` supp ON purch.supplier_id=supp.supplier_id
	LEFT JOIN `0_debtor_trans` sales ON tax.trans_no=sales.trans_no AND tax.trans_type=sales.type
	LEFT JOIN `0_cust_branch` cust ON sales.branch_code=cust.branch_code
 SET tax.tax_group_id = IFNULL(supp.tax_group_id, cust.tax_group_id);

ALTER TABLE `0_tax_groups` ADD COLUMN `tax_area` tinyint(1) NOT NULL DEFAULT '0' AFTER `name`;

# shipment options
ALTER TABLE `0_stock_master` ADD COLUMN `shipper_id` INT(11) NOT NULL DEFAULT '0' AFTER `vat_category`;

INSERT INTO `0_stock_category` (`description`, `dflt_tax_type`, `dflt_units`, `dflt_mb_flag`, `dflt_sales_act`, `dflt_cogs_act`, `dflt_no_sale`)
	VALUES (@shipping_cat_description, @shipping_tax_type, @shipping_units, 'T', @shipping_sales_act, @shipping_cogs_act, '1');

SET @shipment_cat=LAST_INSERT_ID();

INSERT INTO `0_stock_master` (`stock_id`, `tax_type_id`, `description`, `units`, `mb_flag`, `sales_account`, `no_sale`, `no_purchase`, `vat_category`, `category_id`, `shipper_id`, `inactive`)
	SELECT shipper.shipper_name, @shipping_tax_type, shipper.shipper_name, @shipping_units, 'T', @shipping_sales_act, 1, 1, 0, @shipment_cat, shipper.shipper_id, shipper.inactive
		FROM `0_shippers` shipper;

ALTER TABLE `0_sales_orders` CHANGE COLUMN `ship_via` `ship_via` varchar(20) NOT NULL DEFAULT '';

UPDATE `0_sales_orders` ord
	LEFT JOIN `0_shippers` ship ON  ord.ship_via=ship.shipper_id
	LEFT JOIN `0_stock_master` stock ON stock.shipper_id=ship.shipper_id
	SET ord.ship_via=stock.stock_id;

ALTER TABLE `0_debtor_trans` CHANGE COLUMN `ship_via` `ship_via` varchar(20) NOT NULL DEFAULT '';

UPDATE `0_debtor_trans` trans
	LEFT JOIN `0_shippers` ship ON  trans.ship_via=ship.shipper_id
	LEFT JOIN `0_stock_master` stock ON stock.shipper_id=ship.shipper_id
	SET trans.ship_via=stock.stock_id;

ALTER TABLE `0_cust_branch` CHANGE COLUMN `default_ship_via` `default_ship_via` varchar(20) NOT NULL DEFAULT '';

UPDATE `0_cust_branch` branch
	LEFT JOIN `0_shippers` ship ON  branch.default_ship_via=ship.shipper_id
	LEFT JOIN `0_stock_master` stock ON stock.shipper_id=ship.shipper_id
	SET branch.default_ship_via=stock.stock_id;

ALTER TABLE `0_tax_group_items` DROP COLUMN `tax_shipping`;

# new debug trail
DROP TABLE `1_sql_trail`;
CREATE TABLE `1_db_trail` (
		`id` int(11) NOT NULL AUTO_INCREMENT,
		`stamp` timestamp DEFAULT CURRENT_TIMESTAMP,
		`user` tinyint(3) unsigned NOT NULL DEFAULT '0',
		`msg`  varchar(255) DEFAULT '',
		`entry`  varchar(255) DEFAULT '',
		`data` text DEFAULT NULL,
	PRIMARY KEY (`id`)
	) ENGINE=MyISAM;
