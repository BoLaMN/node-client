Model = require './persisted-model'
Mongo = require './adapter/mongo'

Adapter = Mongo.define 'db'

Order = Model.define 'Order', items: [ String ], orderDate: Date, qty: Number

Order.adapter Adapter
Order.belongsTo 'Customer'

Customer = Model.define 'Customer', name: String
Customer.adapter Adapter
Customer.hasMany 'Order', { as: 'orders', foreignKey: 'customerId' }

Physician = Model.define 'Physician', name: String
Physician.adapter Adapter
Physician.hasMany 'Patient', { through: 'Appointment' }

Patient = Model.define 'Patient', name: String
Patient.adapter Adapter
Patient.hasMany 'Physician', { through: 'Appointment' }

Appointment = Model.define 'Appointment', physicianId: Number, patientId: Number, appointmentDate: Date
Appointment.belongsTo 'Patient'
Appointment.belongsTo 'Physician'
Appointment.adapter Adapter

Assembly = Model.define 'Assembly', name: String
Assembly.adapter Adapter
Assembly.hasAndBelongsToMany 'Part'

Part = Model.define 'Part', partNumber: String
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
