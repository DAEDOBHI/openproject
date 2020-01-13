#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe Project::Scopes::VisibleWithActivatedTimeActivity, type: :model do
  let!(:activity) { FactoryBot.create(:time_entry_activity) }
  let!(:project) { FactoryBot.create(:project) }
  let!(:other_project) { FactoryBot.create(:project) }
  let(:project_permissions) { [:view_time_entries] }
  let(:other_project_permissions) { [:view_time_entries] }
  let(:current_user) do
    FactoryBot.create(:user).tap do |u|
      FactoryBot.create(:member,
                        project: project,
                        principal: u,
                        roles: [FactoryBot.create(:role, permissions: project_permissions)])

      FactoryBot.create(:member,
                        project: other_project,
                        principal: u,
                        roles: [FactoryBot.create(:role, permissions: other_project_permissions)])
    end
  end

  before do
    login_as(current_user)
  end

  describe '.fetch' do
    subject { described_class.fetch(activity) }

    context 'without project specific overrides' do
      context 'and being active' do
        it 'returns all projects' do
          is_expected
            .to match_array [project, other_project]
        end
      end

      context 'and not being active' do
        before do
          activity.update_attribute(:active, false)
        end

        it 'returns no projects' do
          is_expected
            .to be_empty
        end
      end

      context 'and having only view_own_time_entries_permission' do
        let(:project_permissions) { [:view_own_time_entries] }
        let(:other_project_permissions) { [:view_own_time_entries] }

        it 'returns all projects' do
          is_expected
            .to match_array [project, other_project]
        end
      end

      context 'and having no view permission' do
        let(:project_permissions) { [] }
        let(:other_project_permissions) { [] }

        it 'returns all projects' do
          is_expected
            .to be_empty
        end
      end
    end

    context 'with project specific overrides' do
      before do
        TimeEntryActivitiesProject.insert(activity_id: activity.id, project_id: project.id, active: true)
        TimeEntryActivitiesProject.insert(activity_id: activity.id, project_id: other_project.id, active: false)
      end

      context 'and being active' do
        it 'returns the project the activity is activated in' do
          is_expected
            .to match_array [project]
        end
      end

      context 'and not being active' do
        before do
          activity.update_attribute(:active, false)
        end

        it 'returns only the projects the activity is activated in' do
          is_expected
            .to match_array [project]
        end
      end
    end
  end
end