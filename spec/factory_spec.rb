RSpec.describe Aquaduct do
  RSpec::Matchers.define :define_const do |const|
    match do |mod|
      mod.const_defined? const
    end
  end

  it 'includes Package and PackageChanneler' do
    make_aquaduct_with_channels

    expect(@module).to define_const :Package
    expect(@module).to define_const :PackageChanneler
  end

  it 'include Custom and CustomChanneler given custom entity' do
    make_aquaduct_with_channels :custom

    expect(@module).to define_const :Custom
    expect(@module).to define_const :CustomChanneler
  end

  it 'exposes channel method from channeler' do
    make_aquaduct_with_channels
    expect(@package_channeler_class).to receive(:channel).with :foo
    @module.channel :foo
  end

  it 'accepts custom model' do
    class CustomModel
      include ActiveModel::Model
      attr_accessor :id, :channel
    end

    make_aquaduct_with_channels CustomModel do
      advance_through %i[channeled]
    end
    channeled = @module.channel spy, @package_class.channeled

    expect(@module).to define_const :CustomModel
    expect(@module).to define_const :CustomModelChanneler
    expect(channeled.all.first).to be_a CustomModel
  end
end
