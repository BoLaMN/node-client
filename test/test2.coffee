Model = require '../src/persisted-model'
Mongo = require '../src/adapter/mongo'

Adapter = Mongo.define 'db'

Order = Model.define 'Order', items: [ 'string' ], orderDate: 'date', qty: 'number'

Order.adapter Adapter
Order.belongsTo 'Customer'

Customer = Model.define 'Customer', name: 'string'
Customer.adapter Adapter
Customer.hasMany 'Order', { as: 'orders', foreignKey: 'customerId' }

Physician = Model.define 'Physician', name: 'string'
Physician.adapter Adapter
Physician.hasMany 'Patient', { through: 'Appointment' }

Patient = Model.define 'Patient', name: 'string'
Patient.adapter Adapter
Patient.hasMany 'Physician', { through: 'Appointment' }

Appointment = Model.define 'Appointment', physicianId: 'number', patientId: 'number', appointmentDate: 'date'
Appointment.belongsTo 'Patient'
Appointment.belongsTo 'Physician'
Appointment.adapter Adapter

Assembly = Model.define 'Assembly', name: 'string'
Assembly.adapter Adapter
Assembly.hasAndBelongsToMany 'Part'

Part = Model.define 'Part', partNumber: 'string'
Part.adapter Adapter
Part.hasAndBelongsToMany 'Assembly'

Author  = Model.define 'Author'
Author.adapter Adapter
Author.hasOne 'Picture', { as: 'avatar', polymorphic: foreignKey: 'imageableId', discriminator: 'imageableType' }

Reader  = Model.define 'Reader'
Reader.adapter Adapter
Reader.hasOne 'Picture', { as: 'imageable', polymorphic: foreignKey: 'imageableId', discriminator: 'imageableType' }

Picture = Model.define 'Picture'
Picture.adapter Adapter

module.exports =
  Customer: Customer
  Order: Order
  Physician: Physician
  Patient: Patient
  Appointment: Appointment
  Assembly: Assembly
  Part: Part
  Author: Author
  Reader: Reader
  Picture: Picture