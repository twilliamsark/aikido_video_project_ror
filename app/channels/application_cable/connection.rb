module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_teacher

    def connect
      set_current_teacher || reject_unauthorized_connection
    end

    private
      def set_current_teacher
        if session = Session.find_by(id: cookies.signed[:session_id])
          self.current_teacher = session.teacher
        end
      end
  end
end
