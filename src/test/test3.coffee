
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
  order.customer.update customer2
  order.customer.get console.log

Order.create
  orderDate: new Date
  items: [ 'Phone' ]
.then (order) ->
  console.log order
  order.customer.create name: 'Smith'
.then (customer2) ->
  console.log order, customer2
  order.save (err, order) ->
    order2 = order
  customer3 = order.customer.build name: 'Tom'
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

Physician.create
  name: 'Dr John'
.then (physician1) ->
  Physician.create
    name: 'Dr Smith'
.then (physician2) ->
  Patient.create
    name: 'Mary'
.then (patient1) ->
  Patient.create
    name: 'Ben'
.then (patient2) ->
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

Assembly.create
  name: 'car'
.then (assembly) ->
  Part.create
    partNumber: 'engine'
.then (part) ->
  console.log assembly
  assembly.parts
.then (parts) ->
  console.log 'Parts: ', parts
  part3 = assembly.parts.build(partNumber: 'door')
  console.log 'Part3: ', part3, part3.constructor.modelName
  assembly.parts.create
    partNumber: 'door'
.then (part4) ->
  console.log 'Part4: ', part4, part4.constructor.modelName
  Assembly.find
    include: 'parts'
.then (assemblies) ->
  console.log 'Assemblies: ', assemblies
