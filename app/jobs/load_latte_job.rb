class LoadLatteJob < ApplicationJob
  queue_as :default

  def perform(current_user)
    ActionCable.server.broadcast "latte_info_#{current_user.id}",
      latte_info: 'good'
    agent = Mechanize.new
    agent.agent.http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    logger.info "Latte Account Name:#{current_user.latte_account.name}"
    logger.info "Latte Account password:#{current_user.latte_account.password}\n\n\n\n\n\n\n\n\n"
    ActionCable.server.broadcast "latte_info_#{current_user.id}", latte_info: 'Initialized'
    page = agent.get('https://login.brandeis.edu/?factors=BRANDEIS.EDU,ldapauth&cosign-moodle2-prod&https://moodle2.brandeis.edu/')
    form = page.form('f')
    form.field_with(:id => "login").value = current_user.latte_account.name
    form.field_with(:id => "password").value = current_user.latte_account.password
    page = agent.submit(form, form.buttons_with(:type => /submit/)[0])
    ActionCable.server.broadcast "latte_info_#{current_user.id}", latte_info: 'Logged in'


    hw_count = 0
    page.links_with(css: "a.course_show").each do |link|
      if link.text =~ /^161/
        course_page = link.click
        course_page.links_with(css: "li.assign div.activityinstance a").each do |a_link|
          hw_count += 1
        end
      end
    end
    ActionCable.server.broadcast "latte_info_#{current_user.id}", latte_info: "Expect to load #{hw_count} items."
    hw_count2 = 0
    page.links_with(css: "a.course_show").each do |link|
      if link.text =~ /^161/
        course_page = link.click
        course_page.links_with(css: "li.assign div.activityinstance a").each do |a_link|
          hw_count2 += 1
          assignment_page = a_link.click
          ActionCable.server.broadcast "latte_info_#{current_user.id}", latte_info: "Now loading #{hw_count2}/#{hw_count} items."
          a_title = assignment_page.xpath("//div[@role='main']/h2/text()")
          ActionCable.server.broadcast "latte_info_#{current_user.id}", latte_info: "#{a_title}"
          a_sub_status = assignment_page.xpath("//td[contains(., 'Submission status')]/following-sibling::td/text()")
          ActionCable.server.broadcast "latte_info_#{current_user.id}", latte_info: "#{a_sub_status}"
          a_due_date = assignment_page.xpath("//td[contains(., 'Due date')]/following-sibling::td/text()")
          ActionCable.server.broadcast "latte_info_#{current_user.id}", latte_info: "#{a_due_date}"
          ActionCable.server.broadcast "latte_info_#{current_user.id}", latte_info: "Entered assignment page"
          ActionCable.server.broadcast "latte_info_#{current_user.id}", latte_info: "<br/>"
        end
      end
    end
  end
end
