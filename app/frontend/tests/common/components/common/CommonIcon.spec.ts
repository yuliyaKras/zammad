// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import CommonIcon from '@common/components/common/CommonIcon.vue'
import { getWrapper } from '@tests/support/components'

describe('CommonIcon.vue', () => {
  it('renders icon', () => {
    const wrapper = getWrapper(CommonIcon, {
      props: { name: 'arrow-left' },
    })
    expect(wrapper.classes()).toContain('icon')
  })
  it('renders icon with animation', () => {
    const wrapper = getWrapper(CommonIcon, {
      props: { name: 'cog', animation: 'spin' },
    })
    expect(wrapper.classes()).toContain('animate-spin')
  })
  it('renders icon with small size', () => {
    const wrapper = getWrapper(CommonIcon, {
      props: { name: 'cog', size: 'small' },
    })

    expect(wrapper.attributes().width).toEqual('20')
    expect(wrapper.attributes().height).toEqual('20')
  })
  it('renders a decorative icon', () => {
    const wrapper = getWrapper(CommonIcon, {
      props: { name: 'cog', decorative: true },
    })

    expect(wrapper.attributes()['aria-hidden']).toEqual('true')
  })
  it('triggers click handler of icon', () => {
    const wrapper = getWrapper(CommonIcon, {
      props: { name: 'dashboard' },
    })

    wrapper.trigger('click')
    expect(wrapper.emitted('click')).toHaveLength(1)
  })
})