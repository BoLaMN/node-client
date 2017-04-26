{
  Customer
  Order
  Physician
  Patient
  Appointment
  Assembly
  Part
  Author
  Reader
  Picture } = require './test2'

order1 = undefined
order2 = undefined
order3 = undefined

customer1 = undefined

Customer.create
  name: 'John'
.then (customer) ->
  Order.create
    customerId: customer.id
    orderDate: new Date
    items: [ 'Book' ]
.then (order) ->
  order1 = order
  order.customer.get console.log
  order.customer.get true, console.log
  Customer.create name: 'Mary'
.then (customer2) ->
  order1.customer.update customer2
  order1.customer.get console.log

Order.create
  orderDate: new Date
  items: [ 'Phone' ]
.then (order) ->
  order2 = order
  order.customer.create name: 'Smith'
.then (customer2) ->
  console.log order2, customer2
  order.save (err, order) ->
    order2 = order
  customer3 = order2.customer.build name: 'Tom'
  console.log 'Customer 3', customer3


order3 = undefined
customer1 = undefined

Customer.create
  name: 'Ray'
.then (customer) ->
  customer1 = customer
  Order.create
    customerId: customer.id
    qty: 3
    orderDate: new Date
.then (order) ->
  order3 = order
  customer1.orders.create
    orderDate: new Date
    qty: 4
.then (order) ->
  customer1.orders.get(where: qty: 4).then (results) ->

    customer1.orders.findById(order3.id).then (results) ->
      customer1.orders.destroy order3.id

physician1 = undefined
physician2 = undefined
patient1 = undefined
patient2 = undefined
patient3 = undefined

Physician.create
  name: 'Dr John'
.then (physician) ->
  physician1 = physician
  Physician.create
    name: 'Dr Smith'
.then (physician) ->
  physician2 = physician
  Patient.create
    name: 'Mary'
.then (patient) ->
  patient1 = patient
  Patient.create
    name: 'Ben'
.then (patient) ->
  patient2 = patient
  Appointment.create
    appointmentDate: new Date
    physicianId: physician1.id
    patientId: patient1.id
.then (appt1) ->
  Appointment.create
    appointmentDate: new Date
    physicianId: physician1.id
    patientId: patient2.id
.then (appt2) ->
  physician1.patients.get { where: name: 'Mary' }, console.log
  patient1.physicians.get console.log
  patient3 = patient1.physicians.build(name: 'Dr X')
  console.log 'Physician 3: ', patient3, patient3.constructor.modelName
  patient1.physicians.create
    name: 'Dr X'
.then (patient4) ->
  console.log 'Physician 4: ', patient4, patient4.constructor.modelName

assembly1 = undefined

Assembly.create
  name: 'car'
.then (assembly) ->
  assembly1 = assembly
  Part.create
    partNumber: 'engine'
.then (part) ->
  console.log assembly1
  assembly1.parts.get
.then (parts) ->
  console.log 'Parts: ', parts
  part3 = assembly1.parts.build(partNumber: 'door')
  console.log 'Part3: ', part3, part3.constructor.modelName
  assembly1.parts.create
    partNumber: 'door'
.then (part4) ->
  console.log 'Part4: ', part4, part4.constructor.modelName
  Assembly.find
    include: 'parts'
.then (assemblies) ->
  console.log 'Assemblies: ', assemblies
