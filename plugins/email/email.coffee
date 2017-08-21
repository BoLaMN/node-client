attachments = (data) ->
  li = ''

  for attachment in data
    li += """
      <li>
        <strong>filename:</strong>
        <span>#{attachment.filename}</span>

        <br>

        <strong>path:</strong>
        <span>#{attachment.path}</span>

        <br>

        <strong>contentType:</strong>
        <span>#{attachment.contentType}</span>
      </li>"""

  li
  
module.exports = (emails) ->
  html = """
    <style>
      .frame {
        display: block;
        width: 800px;
        height: 500px;
      }
    </style>

    <h1>emails</h1>
    <ul>"""

  for email in emails
    html += """<li>
      <h3>#{email.subject}
        <small>#{email._date}</small>
      </h3>
      
      <strong>to:</strong>
      <span>#{email.to}</span>
      
      <br>
      
      <strong>from:</strong>
      <span>#{email.from}</span>

      <p></p>

      <strong>attachments:</strong>
      <ul> #{ attachments(email.attachments) }</ul>

      <p></p>

      <strong>html:</strong>
      <iframe src="data:text/html;charset=utf-8,#{email.html}" class="frame"></iframe>

      <p></p> 
      
      <strong>text:</strong>
      <pre>#{email.text}</pre>
    </li>"""
  
  html + "</ul>"

